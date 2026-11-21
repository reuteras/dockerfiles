FROM golang:1.27-alpine@sha256:70bd7ddea8b6cbe5d6943cde279d6b67feb10cc924fb9100d1d8757c1575b280 AS build

WORKDIR /go/src/github.com/wader/fq

ARG BUILD_VERSION
ARG ARCHIVE_URL=https://github.com/wader/fq/archive/

ENV GO111MODULE on
ENV CGO_ENABLED 0

# hadolint ignore=DL3018
RUN apk update && \
    apk add --no-cache \
	build-base \
    	ca-certificates \
	curl \
	git && \
    update-ca-certificates && \
    go install github.com/wader/fq@master

FROM alpine:3.24.1@sha256:28bd5fe8b56d1bd048e5babf5b10710ebe0bae67db86916198a6eec434943f8b

# Alpine security updates the official image does not have yet.
RUN apk upgrade --no-cache

USER 65534

COPY --from=build /go/bin/fq /fq

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD ["/bin/sh", "-c", "/fq --version || exit 1"]

ENTRYPOINT ["/fq", "-cU"]
