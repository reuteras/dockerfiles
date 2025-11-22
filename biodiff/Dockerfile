FROM rust:1.83-bookworm as builder
WORKDIR /diff
RUN cargo install biodiff

FROM debian:bookworm-20250109-slim
WORKDIR /diff

RUN apt-get update && \
    apt-get dist-upgrade -y && \
    rm -rf /var/lib/apt/lists/*

COPY --from=builder /usr/local/cargo/bin/biodiff /usr/local/bin/biodiff

USER nobody

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD /usr/local/bin/biodiff --help || exit 1

CMD ["/bin/bash"]

