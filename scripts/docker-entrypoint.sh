#!/bin/bash

export PGPASSFILE="${POSTGRES_PASS_FILE}"

NOW_DATE=$(date +%Y-%m-%d_%H_%M_%S)
ZIP_FILENAME="${NOW_DATE}-backup.tar.xz"
DUMP_FILENAME="${DUMP_FILENAME:-db.dump}"

TIMEFORMAT="%R"
NO_ERRORS=1

: ${PUSHGATEWAY_JOB:=${POSTGRES_HOSTNAME}}


function check_constraint_variable() {
	if [ -z "${BUCKET_BACKUP_DB}" ]
	then
		echo "ERROR! Variable BUCKET_BACKUP_DB is empty"
		NO_ERRORS=0
	fi

	if [ -z "${AWS_ACCESS_KEY_ID}" ]
	then
		echo "ERROR! Variable AWS_ACCESS_KEY_ID is empty"
		NO_ERRORS=0
	fi

	if [ -z "${AWS_SECRET_ACCESS_KEY}" ]
	then
		echo "ERROR! Variable AWS_SECRET_ACCESS_KEY is empty"
		NO_ERRORS=0
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
			NO_ERRORS=1
		else
			DUMP_DURATION_SECONDS=$(( SECONDS - start_seconds ))
			echo "Backup created"
			echo "Uncompress backup size (bytes): ${DUMP_SIZE}"
			echo "Backup execution time (s): ${DUMP_DURATION_SECONDS}"
		fi
	else
		echo "ERROR creating backup"
		NO_ERRORS=1
	fi
}


function compress() {

	WORKDIR=$(pwd)
	cd ${POSTGRES_DUMP_PATH}

	echo "Compressing backup"
	local start_seconds=${SECONDS}

	tar cvJf ${ZIP_FILENAME} ${DUMP_FILENAME}

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

	aws s3 cp ${POSTGRES_DUMP_PATH}/${ZIP_FILENAME} s3://${BUCKET_BACKUP_DB} --quiet

	UPLOAD_DURATION_SECONDS=$(( SECONDS - start_seconds ))
	echo "Uploaded backup"
	echo "Upload execution time (s): ${UPLOAD_DURATION_SECONDS}"
}


function clean_dump() {

	echo "Cleaning temporary files"
	rm -f ${POSTGRES_DUMP_PATH}/*
}


function push_metrics() {

	CREATED_DATE_SECONDS=$(date +%s)

# No indent
cat <<EOF | curl -s --data-binary @- ${PUSHGATEWAY_HOST}/metrics/job/${PUSHGATEWAY_JOB}
# HELP backup_db outcome of the backup database job (0=failed, 1=success).
# TYPE backup_db gauge
backup_db{label="${POSTGRES_HOSTNAME}"} ${NO_ERRORS}
# HELP backup_duration_seconds duration of each stage execution in seconds.
# TYPE backup_duration_seconds gauge
backup_duration_seconds{label="${POSTGRES_HOSTNAME}",stage="dump"} ${DUMP_DURATION_SECONDS:-0}
backup_duration_seconds{label="${POSTGRES_HOSTNAME}",stage="compress"} ${COMPRESS_DURATION_SECONDS:-0}
backup_duration_seconds{label="${POSTGRES_HOSTNAME}",stage="upload"} ${UPLOAD_DURATION_SECONDS:-0}
# HELP backup_duration_seconds_total duration of the script execution in seconds.
# TYPE backup_duration_seconds_total gauge
backup_duration_seconds_total{label="${POSTGRES_HOSTNAME}"} ${BACKUP_DURATION_SECONDS:-0}
# HELP backup_size size of backup in bytes.
# TYPE backup_size gauge
backup_size_bytes{label="${POSTGRES_HOSTNAME}"} ${COMPRESS_SIZE:-0}
# HELP backup_created_date_seconds created date in seconds.
# TYPE backup_created_date_seconds gauge
backup_created_date_seconds{label="${POSTGRES_HOSTNAME}"} ${CREATED_DATE_SECONDS}
EOF

}


function main() {

	local start_seconds=${SECONDS}

	check_constraint_variable

	if [ ${NO_ERRORS} -eq 1 ]
	then
		mkdir -p ${POSTGRES_DUMP_PATH}

		# Create pgpass file if not exists
		if [ ! -f ${PGPASSFILE} ]
		then
			create_pgpass
		fi

		dump_all

		if [ ${NO_ERRORS} -eq 1 ]
		then
			compress
			upload_s3
			clean_dump
		fi
	fi

	BACKUP_DURATION_SECONDS=$(( SECONDS - start_seconds ))

    if [ -z "${PUSHGATEWAY_HOST}" ]
    then
    	echo "Warning, 'PUSHGATEWAY_HOST' environment variable not defined, metrics cannot be published"
	    exit 0
    fi

	push_metrics
}

main
