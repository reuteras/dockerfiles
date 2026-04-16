FROM golang:1.25-alpine AS build

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

FROM alpine:3.23

USER nobody

COPY --from=build /go/bin/fq /fq

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD /fq --version || exit 1

ENTRYPOINT ["/fq", "-cU"]
