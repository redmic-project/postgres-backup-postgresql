ARG ALPINE_IMAGE_TAG=3.13

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

ARG CURL_VERSION=7.78.0-r0 \
	POSTGRESQL_CLIENT_VERSION=13.4-r0 \
	BASH_VERSION=5.1.0-r0

RUN apk update && \
	apk list \
		curl \
		postgresql-client \
		bash && \
	apk add --no-cache \
		curl="${CURL_VERSION}" \
		postgresql-client="${POSTGRESQL_CLIENT_VERSION}" \
		bash="${BASH_VERSION}"

ARG GLIBC_VERSION=2.33-r0 \
	AWS_CLI_VERSION=2.0.30

# hadolint ignore=DL3018
RUN curl -sL https://alpine-pkgs.sgerrand.com/sgerrand.rsa.pub -o /etc/apk/keys/sgerrand.rsa.pub && \
	curl -sL "https://github.com/sgerrand/alpine-pkg-glibc/releases/download/${GLIBC_VERSION}/glibc-${GLIBC_VERSION}.apk" -o glibc.apk && \
	curl -sL "https://github.com/sgerrand/alpine-pkg-glibc/releases/download/${GLIBC_VERSION}/glibc-bin-${GLIBC_VERSION}.apk" -o glibc-bin.apk && \
	apk add --no-cache \
		glibc.apk \
		glibc-bin.apk && \
	rm -rf \
		glibc.apk \
		glibc-bin.apk \
		/var/cache/apk/* && \
	curl -s "https://awscli.amazonaws.com/awscli-exe-linux-x86_64-${AWS_CLI_VERSION}.zip" -o awscliv2.zip && \
	unzip awscliv2.zip && \
	./aws/install && \
	rm -rf \
		awscliv2.zip \
		./aws \
		/usr/local/aws-cli/v2/*/dist/aws_completer \
		/usr/local/aws-cli/v2/*/dist/awscli/data/ac.index \
		/usr/local/aws-cli/v2/*/dist/awscli/examples

ENTRYPOINT ["/docker-entrypoint.sh"]
