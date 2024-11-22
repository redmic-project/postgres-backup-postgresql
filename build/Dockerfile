ARG ALPINE_IMAGE_TAG=3.18.0

FROM alpine:${ALPINE_IMAGE_TAG}

LABEL maintainer="info@redmic.es"

ARG CURL_VERSION \
	POSTGRESQL_CLIENT_NAME \
	POSTGRESQL_CLIENT_VERSION \
	BASH_VERSION \
	AWS_CLI_VERSION

RUN apk update && \
	apk list \
		curl \
		"${POSTGRESQL_CLIENT_NAME}" \
		aws-cli \
		bash && \
	apk add --no-cache \
		curl="${CURL_VERSION}" \
		"${POSTGRESQL_CLIENT_NAME}=${POSTGRESQL_CLIENT_VERSION}" \
		bash="${BASH_VERSION}" \
		aws-cli="${AWS_CLI_VERSION}"

COPY scripts /

ENV POSTGRES_USER=postgres \
	POSTGRES_PORT=5432 \
	POSTGRES_DUMP_PATH=/tmp/backup \
	POSTGRES_PASS_FILE=/root/.pgpass \
	AWS_DEFAULT_REGION=eu-west-1 \
	PUSHGATEWAY_HOST=pushgateway:9091 \
	AWS_OUTPUT=json

ENTRYPOINT ["/docker-entrypoint.sh"]
