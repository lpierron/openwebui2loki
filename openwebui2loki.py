#!/usr/bin/env python3
"""
OpenWebUI to Loki - Extract logs from OpenWebUI SQLite database and send to Loki
"""

import argparse
import json
import logging
import os
import sqlite3
import sys
import time
from datetime import datetime
from typing import Dict, List, Optional, Union

import requests

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
)
logger = logging.getLogger("openwebui2loki")


class OpenWebUILoki:
    """Extract logs from OpenWebUI SQLite database and send to Loki"""

    def __init__(
        self,
        db_path: str,
        audit_log_path: Optional[str] = None,
        loki_url: str = "http://localhost:3100/loki/api/v1/push",
        batch_size: int = 100,
        interval: int = 60,
        labels: Dict[str, str] = None,
    ):
        """
        Initialize the OpenWebUI to Loki connector

        Args:
            db_path: Path to the SQLite database
            audit_log_path: Path to the audit log file (optional)
            loki_url: URL of the Loki push API
            batch_size: Number of logs to send in a single batch
            interval: Interval in seconds between log extraction runs
            labels: Additional labels to add to the logs
        """
        self.db_path = db_path
        self.audit_log_path = audit_log_path
        self.loki_url = loki_url
        self.batch_size = batch_size
        self.interval = interval
        self.labels = labels or {}
        
        # Add default labels if not provided
        if "job" not in self.labels:
            self.labels["job"] = "openwebui"
        if "source" not in self.labels:
            self.labels["source"] = "openwebui"

        # State tracking
        self.last_audit_log_position = 0
        self.last_chat_id = None
        self.last_user_id = None
        self.last_timestamp = int(time.time())

    def connect_db(self) -> sqlite3.Connection:
        """Connect to the SQLite database"""
        try:
            conn = sqlite3.connect(self.db_path)
            conn.row_factory = sqlite3.Row
            return conn
        except sqlite3.Error as e:
            logger.error(f"Error connecting to database: {e}")
            raise

    def extract_user_logs(self) -> List[Dict]:
        """Extract user logs from the database"""
        logs = []
        
        # Extract logs from database
        try:
            conn = self.connect_db()
            cursor = conn.cursor()
            
            # Get user activity logs
            cursor.execute(
                """
                SELECT 
                    u.id, u.name, u.email, u.role, u.last_active_at, 
                    u.created_at, u.updated_at
                FROM user u
                WHERE u.last_active_at > ?
                ORDER BY u.last_active_at ASC
                """,
                (self.last_timestamp,),
            )
            
            for row in cursor.fetchall():
                log_entry = {
                    "timestamp": row["last_active_at"] * 1_000_000_000,  # Convert to nanoseconds
                    "source": "database",
                    "type": "user_activity",
                    "user_id": row["id"],
                    "user_name": row["name"],
                    "user_email": row["email"],
                    "user_role": row["role"],
                    "created_at": row["created_at"],
                    "updated_at": row["updated_at"],
                }
                logs.append(log_entry)
                self.last_timestamp = max(self.last_timestamp, row["last_active_at"])
            
            # Get chat logs
            cursor.execute(
                """
                SELECT 
                    c.id, c.user_id, c.title, c.created_at, c.updated_at,
                    u.name as user_name, u.email as user_email
                FROM chat c
                JOIN user u ON c.user_id = u.id
                WHERE c.updated_at > ?
                ORDER BY c.updated_at ASC
                """,
                (self.last_timestamp,),
            )
            
            for row in cursor.fetchall():
                log_entry = {
                    "timestamp": int(datetime.fromisoformat(row["updated_at"]).timestamp()) * 1_000_000_000,
                    "source": "database",
                    "type": "chat_activity",
                    "chat_id": row["id"],
                    "user_id": row["user_id"],
                    "user_name": row["user_name"],
                    "user_email": row["user_email"],
                    "title": row["title"],
                    "created_at": row["created_at"],
                }
                logs.append(log_entry)
                
            conn.close()
        except sqlite3.Error as e:
            logger.error(f"Error extracting logs from database: {e}")
        
        # Extract logs from audit log file if provided
        if self.audit_log_path and os.path.exists(self.audit_log_path):
            try:
                with open(self.audit_log_path, "r") as f:
                    # Seek to the last position
                    f.seek(self.last_audit_log_position)
                    
                    for line in f:
                        line = line.strip()
                        if not line:
                            continue
                            
                        try:
                            audit_log = json.loads(line)
                            
                            # Convert timestamp to nanoseconds
                            timestamp_ns = audit_log.get("timestamp", int(time.time())) * 1_000_000_000
                            
                            log_entry = {
                                "timestamp": timestamp_ns,
                                "source": "audit_log",
                                "type": "api_request",
                                "id": audit_log.get("id"),
                                "user": audit_log.get("user"),
                                "audit_level": audit_log.get("audit_level"),
                                "verb": audit_log.get("verb"),
                                "request_uri": audit_log.get("request_uri"),
                                "response_status_code": audit_log.get("response_status_code"),
                                "source_ip": audit_log.get("source_ip"),
                                "user_agent": audit_log.get("user_agent"),
                            }
                            logs.append(log_entry)
                        except json.JSONDecodeError:
                            logger.warning(f"Invalid JSON in audit log: {line}")
                    
                    # Update the last position
                    self.last_audit_log_position = f.tell()
            except Exception as e:
                logger.error(f"Error extracting logs from audit log: {e}")
        
        return logs

    def format_for_loki(self, logs: List[Dict]) -> Dict:
        """Format logs for Loki push API"""
        streams = {}
        
        for log in logs:
            # Create a unique stream ID based on the log source and type
            source = log.pop("source", "unknown")
            log_type = log.pop("type", "unknown")
            stream_id = f"{source}_{log_type}"
            
            # Get timestamp
            timestamp = log.pop("timestamp", int(time.time() * 1_000_000_000))
            
            # Format the log entry
            log_line = json.dumps(log)
            
            # Add to streams
            if stream_id not in streams:
                # Create labels for this stream
                labels = {
                    **self.labels,
                    "source": source,
                    "type": log_type,
                }
                label_str = "{" + ",".join([f'{k}="{v}"' for k, v in labels.items()]) + "}"
                
                streams[stream_id] = {
                    "stream": labels,
                    "values": []
                }
            
            # Add the log entry to the stream
            streams[stream_id]["values"].append([str(timestamp), log_line])
        
        return {"streams": list(streams.values())}

    def send_to_loki(self, loki_payload: Dict) -> bool:
        """Send logs to Loki"""
        try:
            headers = {"Content-Type": "application/json"}
            response = requests.post(self.loki_url, headers=headers, json=loki_payload)
            
            if response.status_code != 204:
                logger.error(f"Error sending logs to Loki: {response.status_code} - {response.text}")
                return False
                
            return True
        except Exception as e:
            logger.error(f"Error sending logs to Loki: {e}")
            return False

    def run_once(self) -> int:
        """Run a single extraction and push cycle"""
        try:
            # Extract logs
            logs = self.extract_user_logs()
            logger.info(f"Extracted {len(logs)} logs")
            
            if not logs:
                return 0
                
            # Process logs in batches
            for i in range(0, len(logs), self.batch_size):
                batch = logs[i:i+self.batch_size]
                
                # Format for Loki
                loki_payload = self.format_for_loki(batch)
                
                # Send to Loki
                success = self.send_to_loki(loki_payload)
                if not success:
                    logger.warning(f"Failed to send batch {i//self.batch_size + 1}")
            
            return len(logs)
        except Exception as e:
            logger.error(f"Error in run_once: {e}")
            return 0

    def run_forever(self):
        """Run the extraction and push cycle forever"""
        logger.info(f"Starting OpenWebUI to Loki connector")
        logger.info(f"Database: {self.db_path}")
        logger.info(f"Audit log: {self.audit_log_path}")
        logger.info(f"Loki URL: {self.loki_url}")
        logger.info(f"Interval: {self.interval} seconds")
        
        while True:
            try:
                count = self.run_once()
                logger.info(f"Processed {count} logs")
                
                # Sleep until the next interval
                time.sleep(self.interval)
            except KeyboardInterrupt:
                logger.info("Stopping OpenWebUI to Loki connector")
                break
            except Exception as e:
                logger.error(f"Error in run_forever: {e}")
                time.sleep(self.interval)


def main():
    """Main entry point"""
    parser = argparse.ArgumentParser(description="OpenWebUI to Loki connector")
    parser.add_argument("--db", required=True, help="Path to the SQLite database")
    parser.add_argument("--audit-log", help="Path to the audit log file")
    parser.add_argument("--loki-url", default="http://localhost:3100/loki/api/v1/push", help="URL of the Loki push API")
    parser.add_argument("--batch-size", type=int, default=100, help="Number of logs to send in a single batch")
    parser.add_argument("--interval", type=int, default=60, help="Interval in seconds between log extraction runs")
    parser.add_argument("--label", action="append", help="Additional labels to add to the logs (format: key=value)")
    parser.add_argument("--once", action="store_true", help="Run once and exit")
    
    args = parser.parse_args()
    
    # Parse labels
    labels = {}
    if args.label:
        for label in args.label:
            try:
                key, value = label.split("=", 1)
                labels[key] = value
            except ValueError:
                logger.warning(f"Invalid label format: {label}")
    
    # Create connector
    connector = OpenWebUILoki(
        db_path=args.db,
        audit_log_path=args.audit_log,
        loki_url=args.loki_url,
        batch_size=args.batch_size,
        interval=args.interval,
        labels=labels,
    )
    
    # Run
    if args.once:
        connector.run_once()
    else:
        connector.run_forever()


if __name__ == "__main__":
    main()