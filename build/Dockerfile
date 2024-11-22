ARG ALPINE_IMAGE_TAG=3.18.0

FROM alpine:${ALPINE_IMAGE_TAG}

LABEL maintainer="info@redmic.es"

ENV POSTGRES_USER=postgres \
	POSTGRES_PORT=5432 \
	POSTGRES_DUMP_PATH=/tmp/backup \
	POSTGRES_PASS_FILE=/root/.pgpass \
	AWS_DEFAULT_REGION=eu-west-1 \
	PUSHGATEWAY_HOST=pushgateway:9091 \
	AWS_OUTPUT=json

COPY scripts /

ARG CURL_VERSION \
	POSTGRESQL_CLIENT_NAME \
	POSTGRESQL_CLIENT_VERSION \
	BASH_VERSION

RUN apk update && \
	apk list \
		curl \
		"${POSTGRESQL_CLIENT_NAME}" \
		bash && \
	apk add --no-cache \
		curl="${CURL_VERSION}" \
		"${POSTGRESQL_CLIENT_NAME}=${POSTGRESQL_CLIENT_VERSION}" \
		bash="${BASH_VERSION}"

ARG GLIBC_VERSION \
	AWS_CLI_VERSION

# hadolint ignore=DL3018
RUN curl -sL https://alpine-pkgs.sgerrand.com/sgerrand.rsa.pub -o /etc/apk/keys/sgerrand.rsa.pub && \
	curl -sL "https://github.com/sgerrand/alpine-pkg-glibc/releases/download/${GLIBC_VERSION}/glibc-${GLIBC_VERSION}.apk" -o glibc.apk && \
	curl -sL "https://github.com/sgerrand/alpine-pkg-glibc/releases/download/${GLIBC_VERSION}/glibc-bin-${GLIBC_VERSION}.apk" -o glibc-bin.apk && \
	apk add --no-cache \
		glibc.apk \
		glibc-bin.apk && \
	curl -s "https://awscli.amazonaws.com/awscli-exe-linux-x86_64-${AWS_CLI_VERSION}.zip" -o awscliv2.zip && \
	unzip awscliv2.zip && \
	aws/install && \
	aws --version && \
	rm -rf \
		awscliv2.zip \
		aws \
		/usr/local/aws-cli/v2/*/dist/aws_completer \
		/usr/local/aws-cli/v2/*/dist/awscli/data/ac.index \
		/usr/local/aws-cli/v2/*/dist/awscli/examples \
		glibc.apk \
		glibc-bin.apk \
		/var/cache/apk/*

ENTRYPOINT ["/docker-entrypoint.sh"]
