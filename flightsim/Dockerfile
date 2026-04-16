FROM golang:1-alpine3.23 AS build

WORKDIR /go

ENV CGO_ENABLED=0

RUN apk add --no-cache \
        ca-certificates \
        git && \
    update-ca-certificates && \
    go install github.com/alphasoc/flightsim/v2@latest

FROM alpine:3.23

USER nobody

COPY --from=build /go/bin/flightsim /bin/flightsim

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD /bin/flightsim --help || exit 1

ENTRYPOINT ["/bin/flightsim"]
CMD ["--help"]
