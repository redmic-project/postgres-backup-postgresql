FROM alpine:3.7

ENV POSTGRES_PORT="5432" \
	POSTGRES_HOSTNAME="postgresql-master" \
	POSTGRES_USER="postgres" \
	POSTGRES_PASSWORD="password" \
	POSTGRES_PASS_FILE='/root/.pgpass' \
	POSTGRES_DUMP_PATH="/tmp/backup" \
	AWS_DEFAULT_REGION="eu-west-1" \
	AWS_OUTPUT="json"

COPY scripts /usr/local/bin


RUN apk add --no-cache postgresql-client \
 			python3 \
			bash && \
	pip3 install --no-cache-dir --upgrade awscli && \
	rm -rf /var/cache/apk/* && \
	mkdir -p $POSTGRES_DUMP_PATH && \
	chmod +x /usr/local/bin/*.sh

ENTRYPOINT ["docker-entrypoint.sh"]