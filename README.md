# Backup PostgreSQL

Backup PostgreSQL is a service for creating PostgreSQL database backups and uploading them to AWS S3 (or S3-compatible service).

Also sends metrics to Prometheus through Pushgateway.

![alt schema-db](images/schema-backup-db.png)

## Build arguments

| Name | Description |
|-|-|
| ALPINE_IMAGE_TAG | Base Docker image tag |
| CURL_VERSION | cURL dependency version |
| POSTGRESQL_CLIENT_NAME | PostgreSQL-client dependency name |
| POSTGRESQL_CLIENT_VERSION | PostgreSQL-client dependency version |
| AWS_CLI_VERSION | AWS (cli v2) dependency version |
| BASH_VERSION | Bash dependency version |

## Variables

| Name | Description | Default |
|-|-|-|
| POSTGRES_HOSTNAME | Database hostname | changeme |
| POSTGRES_PORT | Database port | 5432 |
| POSTGRES_USER | Database username | postgres |
| POSTGRES_PASSWORD | Database password | changeme |
| EXTRA_DUMP_PARAMS | Additional params for dump | |
| POSTGRES_DUMP_PATH | Temporal path | /tmp/backup |
| POSTGRES_PASS_FILE | PG credentials file path | /root/.pgpass |
| DUMP_FILENAME | File name for uploads | db.dump |
| BUCKET_BACKUP_DB | Bucket name for uploads | backup-db |
| UPLOAD_ENDPOINT_URL | URL for uploads (S3-compatible) | |
| AWS_ACCESS_KEY_ID | AWS credentials | changeme |
| AWS_SECRET_ACCESS_KEY | AWS credentials | changeme |
| AWS_DEFAULT_REGION | AWS region | eu-west-1 |
| AWS_OUTPUT | AWS output format | json |
| PUSHGATEWAY_HOST | Pushgateway hostname | pushgateway:9091 |
| PUSHGATEWAY_JOB | Pushgateway job name | ${POSTGRES_HOSTNAME} |

## Metrics

| Name | Description |
|-|-|
| backup_db{label="redmic"} | Outcome of the backup database job (0=failed, 1=success) |
| backup_duration_seconds{label="redmic",stage="dump"} | Duration of create dump execution in seconds |
| backup_duration_seconds{label="redmic",stage="compress"} | Duration of compress dump execution in seconds |
| backup_duration_seconds{label="redmic",stage="upload"} | Duration of upload backup to S3 execution in seconds |
| backup_size_bytes{label="redmic"} | Duration of the script execution in seconds |
| backup_created_date_seconds{label="redmic"} | Created date in seconds |
