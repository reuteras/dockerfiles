FROM golang:1-alpine AS build

WORKDIR /go/src/github.com/wader/fq

ARG BUILD_VERSION
ARG ARCHIVE_URL=https://github.com/wader/fq/archive/

ENV GO111MODULE on
ENV CGO_ENABLED 0

RUN apk update &&\
    apk add --no-cache ca-certificates curl git gcc build-base && \
    update-ca-certificates && \
	go install github.com/wader/fq@master

FROM alpine:3

COPY --from=build /go/bin/fq /fq

ENTRYPOINT ["/fq", "-cU"]
