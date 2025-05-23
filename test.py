#!/usr/bin/env python3
"""
Test script for OpenWebUI to Loki connector
"""

import json
import logging
import sys
from openwebui2loki import OpenWebUILoki

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
)
logger = logging.getLogger("openwebui2loki-test")

class MockLokiConnector(OpenWebUILoki):
    """Mock Loki connector that prints logs instead of sending them to Loki"""
    
    def send_to_loki(self, loki_payload):
        """Print logs instead of sending them to Loki"""
        logger.info(f"Would send {len(loki_payload['streams'])} streams to Loki")
        
        for stream in loki_payload["streams"]:
            labels = stream["stream"]
            logger.info(f"Stream: {labels}")
            logger.info(f"  Values: {len(stream['values'])} entries")
            
            # Print first 5 entries
            for i, (timestamp, value) in enumerate(stream["values"][:5]):
                try:
                    value_obj = json.loads(value)
                    logger.info(f"  [{i}] {timestamp}: {json.dumps(value_obj, indent=2)}")
                except json.JSONDecodeError:
                    logger.info(f"  [{i}] {timestamp}: {value}")
            
            if len(stream["values"]) > 5:
                logger.info(f"  ... and {len(stream['values']) - 5} more entries")
        
        return True

def main():
    """Main entry point"""
    if len(sys.argv) < 2:
        print(f"Usage: {sys.argv[0]} <db_path> [audit_log_path]")
        sys.exit(1)
    
    db_path = sys.argv[1]
    audit_log_path = sys.argv[2] if len(sys.argv) > 2 else None
    
    # Create connector
    connector = MockLokiConnector(
        db_path=db_path,
        audit_log_path=audit_log_path,
        batch_size=10,
    )
    
    # Run once
    count = connector.run_once()
    logger.info(f"Processed {count} logs")

if __name__ == "__main__":
    main()