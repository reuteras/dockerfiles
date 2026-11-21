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

FROM alpine:3.24.4@sha256:f59abe656b692d901e184be3445e084786602108599d2a51d229c0f5a48c71bf

# Alpine security updates the official image does not have yet.
RUN apk upgrade --no-cache

USER 65534

COPY --from=build /go/bin/fq /fq

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD ["/bin/sh", "-c", "/fq --version || exit 1"]

ENTRYPOINT ["/fq", "-cU"]
