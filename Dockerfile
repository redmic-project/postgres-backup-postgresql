ARG ALPINE_IMAGE_TAG=3.13

FROM alpine:${ALPINE_IMAGE_TAG}

LABEL maintainer="info@redmic.es"

ARG POSTGRES_PASS_FILE="/root/.pgpass" \
	POSTGRES_DUMP_PATH="/tmp/backup"

ENV POSTGRES_PORT="5432" \
	POSTGRES_PASS_FILE="/root/.pgpass" \
	POSTGRES_DUMP_PATH="/tmp/backup" \
	AWS_DEFAULT_REGION="eu-west-1" \
	PUSHGATEWAY_HOST="pushgateway:9091" \
	AWS_OUTPUT="json"

COPY scripts /

ARG CURL_VERSION=7.74.0-r1
ARG POSTGRESQL_CLIENT_VERSION=10.12-r0
ARG BASH_VERSION=5.1.0-r0
ARG XZ_VERSION=5.2.5-r0
RUN apk list \
		curl \
		postgresql-client \
		bash \
		glib \
		xz && \
	echo "http://dl-cdn.alpinelinux.org/alpine/v3.8/main" >> /etc/apk/repositories && \
	apk update && \
	apk add --no-cache \
		curl=${CURL_VERSION} \
		postgresql-client=${POSTGRESQL_CLIENT_VERSION} \
		bash=${BASH_VERSION} \
		xz=${XZ_VERSION}

ARG GLIBC_VER=2.33-r0
ARG AWS_CLI_VERSION=2.0.30
ENV GLIBC_VER=${GLIBC_VER}
ENV AWS_CLI_VERSION=${AWS_CLI_VERSION}
# hadolint ignore=DL3018
RUN curl -sL https://alpine-pkgs.sgerrand.com/sgerrand.rsa.pub -o /etc/apk/keys/sgerrand.rsa.pub && \
	curl -sLO https://github.com/sgerrand/alpine-pkg-glibc/releases/download/${GLIBC_VER}/glibc-${GLIBC_VER}.apk && \
	curl -sLO https://github.com/sgerrand/alpine-pkg-glibc/releases/download/${GLIBC_VER}/glibc-bin-${GLIBC_VER}.apk && \
	apk add --no-cache \
		glibc-${GLIBC_VER}.apk \
		glibc-bin-${GLIBC_VER}.apk && \
	curl -s "https://awscli.amazonaws.com/awscli-exe-linux-x86_64-${AWS_CLI_VERSION}.zip" -o "awscliv2.zip" && \
	unzip awscliv2.zip && \
	./aws/install && \
	rm -rf \
		awscliv2.zip \
		./aws \
		/usr/local/aws-cli/v2/*/dist/aws_completer \
		/usr/local/aws-cli/v2/*/dist/awscli/data/ac.index \
		/usr/local/aws-cli/v2/*/dist/awscli/examples && \
	rm glibc-${GLIBC_VER}.apk && \
	rm glibc-bin-${GLIBC_VER}.apk && \
	rm -rf /var/cache/apk/*

ENTRYPOINT ["/docker-entrypoint.sh"]
