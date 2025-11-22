FROM zeek/zeek:6.0.2

LABEL maintainer="Coding <code@ongoing.today>"

ENV PCAP /pcap
RUN mkdir "${PCAP}"

RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get -y install --no-install-recommends \
        cmake=3.28.3-1 \
        g++=4:13.2.0-2 \
        jq=1.7.1-2 \
        libfl-dev=2.6.4-8.2 \
        libgoogle-perftools-dev=2.10-1 \
        libkrb5-dev=1.20.1-2+deb12u1 \
        libpcap0.8-dev=1.10.4-1 \
        libssl-dev=3.0.13-1~deb12u1 \
        make=4.3-4.1 \
        zlib1g-dev=1:1.2.13.dfsg-1 && \
    zkg install --force --skiptests zeek/spicy-analyzers \
        zeek-community-id \
        zeek/spicy-analyzers || \
    cat /usr/local/zeek/var/lib/zkg/logs/zeek-community-id-build.log && \
    apt-get clean && apt-get autoremove -y && rm -rf /var/lib/apt/lists/*

WORKDIR /output

USER nobody

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD /usr/local/zeek/bin/zeek --version || exit 1

CMD [ "/bin/bash", "-l" ]
