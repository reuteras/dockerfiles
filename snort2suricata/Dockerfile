FROM golang:1.23-alpine3.21

WORKDIR /go/src/app
COPY convert.go .
COPY go.mod .

RUN apk update && \
    apk add --no-cache git=2.47.1-r0 && \
    go mod tidy && \
    go build -o convert . && \
    rm -rf /var/cache/apk/*

USER nobody

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD /go/src/app/convert --help || exit 1

CMD ["/go/src/app/convert"]
