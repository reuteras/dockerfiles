# hadolint ignore=DL3007
FROM zeek/zeek:latest
LABEL maintainer="Coding <code@ongoing.today>"

ENV PCAP /pcap
RUN mkdir "${PCAP}"

# hadolint ignore=DL3008,DL3013
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get -y install --no-install-recommends \
        cmake \
        g++ \
        jq \
        libfl-dev \
        libgoogle-perftools-dev \
        libkrb5-dev \
        libpcap0.8-dev \
        libssl-dev \
		make \
        zlib1g-dev && \
    zkg install --force --skiptests zeek/spicy-analyzers \
        zeek-community-id \
        zeek/spicy-analyzers || \
	cat /usr/local/zeek/var/lib/zkg/logs/zeek-community-id-build.log && \
    apt-get clean && apt-get autoremove -y && rm -rf /var/lib/apt/lists/*

WORKDIR /output
CMD [ "/bin/bash", "-l" ]
