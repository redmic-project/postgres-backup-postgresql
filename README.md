# Backup DB
Backup DB is a docker for create database backup (PostgreSQL)
and uploads to AWS S3. Also sends metrics a Prometheus through
PushGateWay.

![alt schema-db](images/schema-backup-db.png)

# Variables
|          Name         	|          Description          	|      Default      	|
|:---------------------:	|:-----------------------------:	|:-----------------:	|
| POSTGRES_USER         	| Database username             	| postgres          	|
| POSTGRES_PASSWORD     	| Database password             	| password          	|
| POSTGRES_HOSTNAME     	| Database hostname             	| postgresql        	|
| POSTGRES_DUMP_PATH    	| Temporal path                 	| /tmp/backup       	|
| BUCKET_BACKUP_DB      	| Bucket name for upload backup 	|                   	|
| AWS_ACCESS_KEY_ID     	| Credentials AWS               	|                   	|
| AWS_SECRET_ACCESS_KEY 	| Credentials AWS               	|                   	|
| AWS_DEFAULT_REGION    	| Region AWS                    	| eu-west-1         	|
| PUSHGATEWAY_HOST      	| PushGateWay hostname          	| pushgateway:9091  	|
| PUSHGATEWAY_JOB       	| PushGateWay job name          	| POSTGRES_HOSTNAME 	|