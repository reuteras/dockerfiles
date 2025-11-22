FROM debian:bookworm-20250109-slim AS builder

LABEL maintainer="Coding <code@ongoing.today>"

ENV DEBIAN_FRONTEND=noninteractive
# Perl settings -n to don't to tests
ENV UID=1000
ENV GID=1000

WORKDIR /src

SHELL ["/bin/bash", "-eo", "pipefail", "-c"]
RUN apt-get update -yqq && \
    apt-get install -yqq --no-install-recommends \
        autoconf=2.71-3 \
        automake=1:1.16.5-1.3 \
        bison=2:3.8.2+dfsg-1+b1 \
        build-essential=12.9 \
        ca-certificates=20250101 \
        flex=2.6.4-8.2 \
        gettext=0.21.1-1 \
        git=1:2.43.0-1.1 \
        libjson-c-dev=0.17-1 \
        libmaxminddb-dev=1.9.1-1 \
        libnuma-dev=2.0.16-1 \
        libpcap-dev=1.10.4-1 \
        libpcre2-dev=10.42-1 \
        librrd-dev=1.7.2-4+deb12u1 \
        libtool=2.4.7-5 \
        pkg-config=1.8.1-1

RUN git clone https://github.com/ntop/nDPI.git && \
    cd nDPI && \
    ./autogen.sh && \
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

FROM debian:bookworm-20250109-slim

WORKDIR /pcap
ENV PATH="$PATH:/opt/bin"

COPY --from=builder /opt /opt

SHELL ["/bin/bash", "-eo", "pipefail", "-c"]
RUN apt-get update -yqq && \
    apt-get install -yqq --no-install-recommends \
        ca-certificates=20250101 \
        libjson-c-dev=0.17-1 \
        libmaxminddb-dev=1.9.1-1 \
        libnuma-dev=2.0.16-1 \
        libpcap-dev=1.10.4-1 \
        libpcre2-dev=10.42-1 \
        librrd-dev=1.7.2-4+deb12u1 \
        libtool=2.4.7-5 && \
    apt-get clean && \
    apt-get autoclean && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /usr/share/doc && \
    rm -rf /usr/local/share/man /var/cache/debconf/*-old

USER nobody

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD /opt/bin/ndpi-netfilter --help || exit 1

CMD ["/bin/bash"]
