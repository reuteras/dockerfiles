FROM python:3.11-slim
# Testing https://github.com/CERT-Polska/hfinger

LABEL maintainer="Coding <code@ongoing.today>"
ENV DEBIAN_FRONTEND noninteractive
ENV VIRTUAL_ENV=/hfinger/venv
ENV PATH="$VIRTUAL_ENV/bin:$PATH"

USER root

# Install all OS dependencies for fully functional notebook server
# hadolint ignore=DL3003,DL3008,DL3013
RUN apt-get update && apt-get install -yq --no-install-recommends \
    ca-certificates \
    git \
    jq \
    less \
    libmagic1 \
    tshark && \
    git clone https://github.com/CERT-Polska/hfinger.git && \
    cd hfinger && \
    python3 -m venv $VIRTUAL_ENV && \
    pip3 install setuptools && \
    python3 setup.py install && \
    apt-get autoremove -y git ca-certificates && \
    apt-get clean && rm -rf /var/lib/apt/lists/* && \
    rm -rf /var/lib/apt/lists/* /usr/share/doc && \
    rm -rf /hfinger/.git && \
    rm -rf /usr/local/share/man /var/cache/debconf/*-old

USER nobody
WORKDIR /hfinger

