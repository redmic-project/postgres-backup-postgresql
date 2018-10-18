FROM alpine:3.7

LABEL maintainer="info@redmic.es"

ENV POSTGRES_PORT="5432" \
	POSTGRES_HOSTNAME="postgresql" \
	POSTGRES_USER="postgres" \
	POSTGRES_PASSWORD="password" \
	POSTGRES_PASS_FILE='/root/.pgpass' \
	POSTGRES_DUMP_PATH="/tmp/backup" \
	AWS_DEFAULT_REGION="eu-west-1" \
	PUSHGATEWAY_HOST="pushgateway:9091" \
	AWS_OUTPUT="json"

COPY scripts /

RUN apk add --no-cache \
		curl \
		postgresql-client \
		python3 \
		bash && \
	rm -rf /var/cache/apk/* && \
	pip3 install --no-cache-dir --upgrade \
		awscli

ENTRYPOINT ["/docker-entrypoint.sh"]
