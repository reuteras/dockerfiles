FROM golang:1-alpine AS build

WORKDIR /go

RUN apk update &&\
    apk add --no-cache ca-certificates curl git gcc build-base && \
    update-ca-certificates && \
	go install github.com/alphasoc/flightsim@latest

FROM alpine:3

COPY --from=build /go/bin/flightsim /bin/flightsim

ENTRYPOINT ["/bin/flightsim"]
CMD ["--help"]
