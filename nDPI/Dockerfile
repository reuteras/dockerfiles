FROM debian:bullseye-slim AS builder

LABEL maintainer="Coding <code@ongoing.today>"

ENV DEBIAN_FRONTEND=noninteractive
# Perl settings -n to don't to tests
ENV UID=1000
ENV GID=1000

WORKDIR /src

SHELL ["/bin/bash", "-eo", "pipefail", "-c"]
# hadolint ignore=DL3008
RUN apt-get update -yqq && \
    apt-get install -yqq --no-install-recommends \
        autoconf \
        automake \
        bison \
        build-essential \
        ca-certificates \
        flex \
        gettext \
        git \
        libjson-c-dev \
        libmaxminddb-dev \
        libnuma-dev \
        libpcap-dev \
        libpcre2-dev \
        librrd-dev \
        libtool \
        pkg-config

RUN git clone https://github.com/ntop/nDPI.git

WORKDIR /src/nDPI

RUN ./autogen.sh && \
    ./configure --prefix=/opt && \
    make && \
    make install && \
    apt-get remove -y \
        build-essential && \
    apt-get clean && \
    apt-get autoclean && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /usr/share/doc && \
    rm -rf /usr/local/share/man /var/cache/debconf/*-old

FROM debian:bullseye-slim

WORKDIR /pcap
ENV PATH="$PATH:/opt/bin"

COPY --from=builder /opt /opt

SHELL ["/bin/bash", "-eo", "pipefail", "-c"]
# hadolint ignore=DL3008
RUN apt-get update -yqq && \
    apt-get install -yqq --no-install-recommends \
        ca-certificates \
        libjson-c-dev \
        libmaxminddb-dev \
        libnuma-dev \
        libpcap-dev \
        libpcre2-dev \
        librrd-dev \
        libtool && \
    apt-get clean && \
    apt-get autoclean && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /usr/share/doc && \
    rm -rf /usr/local/share/man /var/cache/debconf/*-old

USER nobody

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD /opt/bin/ndpi-netfilter --help || exit 1

CMD ["/bin/bash"]
