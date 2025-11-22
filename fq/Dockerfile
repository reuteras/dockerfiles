FROM golang:1.23-alpine3.21 AS build

WORKDIR /go/src/github.com/wader/fq

ARG BUILD_VERSION
ARG ARCHIVE_URL=https://github.com/wader/fq/archive/

ENV GO111MODULE on
ENV CGO_ENABLED 0

RUN apk update && \
    apk add --no-cache ca-certificates=2025-1-7-r0 curl=8.12.1-r0 git=2.47.1-r0 gcc=14.2.0-r2 build-base=0.5-r3 && \
    update-ca-certificates && \
    go install github.com/wader/fq@master && \
    rm -rf /var/cache/apk/*

FROM alpine:3.21

USER nobody

COPY --from=build /go/bin/fq /fq

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD /fq --version || exit 1

ENTRYPOINT ["/fq", "-cU"]
