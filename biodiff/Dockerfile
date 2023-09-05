FROM rust:1-bookworm as builder
WORKDIR /diff
RUN cargo install biodiff

FROM debian:bookworm-slim
WORKDIR /diff
RUN apt-get update && \
	apt-get dist-upgrade -y && \
	rm -rf /var/lib/apt/lists/*
COPY --from=builder /usr/local/cargo/bin/biodiff /usr/local/bin/biodiff

CMD ["/bin/bash"]

