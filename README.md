# OpenWebUI to Loki

A Python utility to extract user logs from OpenWebUI's SQLite database and send them to Loki for visualization in Grafana.

## Features

- Extracts user activity logs from OpenWebUI's SQLite database
- Processes audit logs from OpenWebUI's audit log file
- Sends logs to Loki in a format suitable for Grafana visualization
- Supports batching and periodic extraction
- Configurable via command-line arguments
- Docker and Docker Compose support for easy deployment

## Installation

### Prerequisites

- Python 3.6 or higher
- OpenWebUI SQLite database
- Loki server (can be set up using the provided Docker Compose file)

### Install Dependencies

```bash
pip install -r requirements.txt
```

## Usage

### Command Line

```bash
python openwebui2loki.py --db /path/to/webui.db --audit-log /path/to/audit.log --loki-url http://localhost:3100/loki/api/v1/push
```

### Options

- `--db`: Path to the SQLite database (required)
- `--audit-log`: Path to the audit log file (optional)
- `--loki-url`: URL of the Loki push API (default: http://localhost:3100/loki/api/v1/push)
- `--batch-size`: Number of logs to send in a single batch (default: 100)
- `--interval`: Interval in seconds between log extraction runs (default: 60)
- `--label`: Additional labels to add to the logs (format: key=value, can be specified multiple times)
- `--once`: Run once and exit (default: run continuously)

## Docker Deployment

### Using Docker Compose

The easiest way to deploy the entire stack (OpenWebUI to Loki connector, Loki, and Grafana) is using Docker Compose:

```bash
docker-compose up -d
```

This will:
1. Start a Loki server on port 3100
2. Start a Grafana server on port 3000
3. Start the OpenWebUI to Loki connector

### Accessing Grafana

1. Open a web browser and navigate to http://localhost:3000
2. Log in with the default credentials (admin/admin)
3. Add Loki as a data source (URL: http://loki:3100)
4. Create dashboards to visualize the OpenWebUI logs

## Example Grafana Queries

### User Activity

```
{source="database", type="user_activity"}
```

### API Requests

```
{source="audit_log", type="api_request"}
```

### Chat Activity

```
{source="database", type="chat_activity"}
```

## License

MIT
