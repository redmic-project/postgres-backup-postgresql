#!/bin/bash

export PGPASSFILE="${POSTGRES_PASS_FILE}"

NOW_DATE=$(date +%Y-%m-%d_%H_%M_%S)
ZIP_FILENAME="${NOW_DATE}-backup.tar.gz"
DUMP_FILENAME="${DUMP_FILENAME:-db.dump}"

TIMEFORMAT="%R"
EXISTS_ERROR=0

: ${PUSHGATEWAY_HOST:="pushgateway:9091"}
: ${PUSHGATEWAY_JOB:=${POSTGRES_HOSTNAME}}


function check_constraint_variable() {
	if [ -z "${BUCKET_BACKUP_DB}" ]
	then
		echo "ERROR! Variable BUCKET_BACKUP_DB is empty"
		EXISTS_ERROR=1
	fi

	if [ -z "${AWS_ACCESS_KEY_ID}" ]
	then
		echo "ERROR! Variable AWS_ACCESS_KEY_ID is empty"
		EXISTS_ERROR=1
	fi

	if [ -z "${AWS_SECRET_ACCESS_KEY}" ]
	then
		echo "ERROR! Variable AWS_SECRET_ACCESS_KEY is empty"
		EXISTS_ERROR=1
	fi
}


function create_pgpass() {

	echo "${POSTGRES_HOSTNAME}:${POSTGRES_PORT}:*:${POSTGRES_USER}:${POSTGRES_PASSWORD}" > ${PGPASSFILE}
	chmod 0600 ${PGPASSFILE}
}


function size_file() {
	echo "$(wc -c <"${1}")"
}

function dump_all() {

	echo "Creating database backup"
	local start_seconds=${SECONDS}

	if pg_dumpall -h ${POSTGRES_HOSTNAME} -U ${POSTGRES_USER} --clean > ${POSTGRES_DUMP_PATH}/${DUMP_FILENAME}
	then
		DUMP_SIZE=$( size_file "${POSTGRES_DUMP_PATH}/${DUMP_FILENAME}" )
		if [ ${DUMP_SIZE} -eq 0 ]; then
			echo "ERROR created empty backup"
			EXISTS_ERROR=1
		else
			DUMP_DURATION_SECONDS=$(( SECONDS - start_seconds ))
			echo "Backup created"
			echo "Uncompress backup size (bytes): ${DUMP_SIZE}"
			echo "Backup execution time (s): ${DUMP_DURATION_SECONDS}"
		fi
	else
		echo "ERROR creating backup"
		EXISTS_ERROR=1
	fi
}


function compress() {

	WORKDIR=$(pwd)
	cd ${POSTGRES_DUMP_PATH}

	echo "Compressing backup"
	local start_seconds=${SECONDS}

	sleep 5
	tar czf ${ZIP_FILENAME} ${DUMP_FILENAME}

	COMPRESS_DURATION_SECONDS=$(( SECONDS - start_seconds ))
	COMPRESS_SIZE=$( size_file "${ZIP_FILENAME}" )

	echo "Backup compressed"
	echo "Compress backup size (bytes): ${COMPRESS_SIZE}"
	echo "Compress execution time (s): ${COMPRESS_DURATION_SECONDS}"

	cd ${WORKDIR}
}


function upload_s3() {

	echo "Uploading backup to S3"
	local start_seconds=${SECONDS}

	sleep 3
	aws s3 cp ${POSTGRES_DUMP_PATH}/${ZIP_FILENAME} s3://${BUCKET_BACKUP_DB}

	UPLOAD_DURATION_SECONDS=$(( SECONDS - start_seconds ))
	echo "Uploaded backup"
	echo "Upload execution time (s): ${UPLOAD_DURATION_SECONDS}"
}


function clean_dump() {

	echo "Cleaning temporary files"
	rm -f ${POSTGRES_DUMP_PATH}/*
}


function push_metrics() {
	# No indent
cat <<EOF | curl --data-binary @- ${PUSHGATEWAY_HOST}/metrics/job/${PUSHGATEWAY_JOB}
# HELP backup_db outcome of the backup database job (1=failed, 0=success).
# TYPE backup_db gauge
backup_db{label="${POSTGRES_HOSTNAME}"} ${EXISTS_ERROR}
# HELP dump_duration_seconds duration of the generate dump execution in seconds.
# TYPE dump_duration_seconds gauge
dump_duration_seconds{label="${POSTGRES_HOSTNAME}"} ${DUMP_DURATION_SECONDS:-0}
# HELP dump_size size of dump.
# TYPE dump_size gauge
dump_size{label="${POSTGRES_HOSTNAME}"} ${DUMP_SIZE:-0}
# HELP compress_duration_seconds duration of the compress dump execution in seconds.
# TYPE compress_duration_seconds gauge
compress_duration_seconds{label="${POSTGRES_HOSTNAME}"} ${COMPRESS_DURATION_SECONDS:-0}
# HELP compress_size size of backup.
# TYPE compress_size gauge
compress_size{label="${POSTGRES_HOSTNAME}"} ${COMPRESS_SIZE:-0}
# HELP upload_backup_to_s3_duration_seconds duration of upload backutp to S3 in seconds.
# TYPE upload_backup_to_s3_duration_seconds gauge
upload_backup_to_s3_duration_seconds{label="${POSTGRES_HOSTNAME}"} ${UPLOAD_DURATION_SECONDS:-0}
# HELP backup_duration_seconds duration of the script execution in seconds.
# TYPE backup_duration_seconds gauge
backup_duration_seconds{label="${POSTGRES_HOSTNAME}"} ${BACKUP_DURATION_SECONDS:-0}
EOF

}


function main() {

	local start_seconds=${SECONDS}

	check_constraint_variable

	if [ ${EXISTS_ERROR} -eq 0 ]
	then
		mkdir -p ${POSTGRES_DUMP_PATH}

		# Create pgpass file if not exists it
		if [ ! -f ${PGPASSFILE} ]
		then
			create_pgpass
		fi

		dump_all

		if [ ${EXISTS_ERROR} -eq 0 ]
		then
			compress
			upload_s3
			clean_dump
		fi
	fi

	BACKUP_DURATION_SECONDS=$(( SECONDS - start_seconds ))
	push_metrics
}

main
