FROM golang:1-alpine

WORKDIR /go/src/app
COPY convert.go .
COPY go.mod .

# hadolint ignore=DL3008,DL3018
RUN apk update && \
    apk add --no-cache git && \
    go mod tidy && \
    go build -o convert . && \
    rm -rf /var/cache/apk/*

USER 65534

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD ["/bin/sh", "-c", "/go/src/app/convert --help || exit 1"]

CMD ["/go/src/app/convert"]
