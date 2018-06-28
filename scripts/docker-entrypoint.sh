#!/bin/bash

export PGPASSFILE="${POSTGRES_PASS_FILE}"

NOW_DATE=$(date +%Y-%m-%d_%H_%M_%S)
ZIP_FILENAME="${NOW_DATE}-backup.tar.gz"
DUMP_FILENAME=${DUMP_FILENAME:-"db.dump"}


function check_constraint_variable() {
	local VALUE=0

	if [[ -z  "${BUCKET_BACKUP_DB}" ]]; then
		echo "ERROR! Variable BUCKET_BACKUP_DB is empty"
		VALUE=1
	fi

	if [[ -z  "${AWS_ACCESS_KEY_ID}" ]]; then
		echo "ERROR! Variable AWS_ACCESS_KEY_ID is empty"
		VALUE=1
	fi

	if [[ -z  "${AWS_SECRET_ACCESS_KEY}" ]]; then
		echo "ERROR! Variable AWS_SECRET_ACCESS_KEY is empty"
		VALUE=1
	fi

	if [[ "$VALUE" == "1" ]]; then
		exit 1
	fi
}


function create_pgpass() {
	echo "${POSTGRES_HOSTNAME}:${POSTGRES_PORT}:*:${POSTGRES_USER}:${POSTGRES_PASSWORD}" > ${PGPASSFILE}
	chmod 0600 ${PGPASSFILE}
}


function dump_all() {
	echo "Creating database backup"
	pg_dumpall -h ${POSTGRES_HOSTNAME} -U ${POSTGRES_USER} --clean > ${POSTGRES_DUMP_PATH}/${DUMP_FILENAME}
}


function compress() {
	echo "Compressing backup"
	WORKDIR=$(pwd)
	cd ${POSTGRES_DUMP_PATH}
	tar czf ${ZIP_FILENAME} ${DUMP_FILENAME}
	cd ${WORKDIR}
}


function upload_s3() {
	echo "Uploading backup to S3"
	aws s3 cp ${POSTGRES_DUMP_PATH}/${ZIP_FILENAME} s3://${BUCKET_BACKUP_DB}
}


function clean_dump() {
	echo "Cleaning temporary files"
	rm -f ${POSTGRES_DUMP_PATH}/*
}


check_constraint_variable

# Create pgpass file if not exists it
if [[ ! -f  ${PGPASSFILE} ]]; then
	create_pgpass
fi

dump_all

if [[ -f  ${POSTGRES_DUMP_PATH}/${DUMP_FILENAME} ]]; then
	compress

	if [[ -f ${POSTGRES_DUMP_PATH}/${ZIP_FILENAME} ]]; then
		upload_s3
	fi

	clean_dump
fi
