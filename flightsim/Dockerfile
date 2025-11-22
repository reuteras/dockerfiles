FROM golang:1.23-alpine3.21 AS build

WORKDIR /go

RUN apk update && \
    apk add --no-cache ca-certificates=2025-1-7-r0 curl=8.12.1-r0 git=2.47.1-r0 gcc=14.2.0-r2 build-base=0.5-r3 && \
    update-ca-certificates && \
    go install github.com/alphasoc/flightsim@latest && \
    rm -rf /var/cache/apk/*

FROM alpine:3.21

USER nobody

COPY --from=build /go/bin/flightsim /bin/flightsim

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD /bin/flightsim --help || exit 1

ENTRYPOINT ["/bin/flightsim"]
CMD ["--help"]
