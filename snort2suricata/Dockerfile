FROM golang:1-alpine

WORKDIR /go/src/app
COPY convert.go .
COPY go.mod .

# hadolint ignore=DL3018
RUN apk update && \
    apk add --no-cache \
        git && \
    go mod tidy && \
    go build -o convert .

CMD ["/go/src/app/convert"]
