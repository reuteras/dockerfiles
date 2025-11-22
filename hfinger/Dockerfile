FROM python:3.11-slim

LABEL maintainer="Coding <code@ongoing.today>"
ENV DEBIAN_FRONTEND noninteractive
ENV VIRTUAL_ENV=/hfinger/venv
ENV PATH="$VIRTUAL_ENV/bin:$PATH"

USER root

# Install all OS dependencies for fully functional notebook server
RUN apt-get update && apt-get install -yq --no-install-recommends \
    ca-certificates=20250101 \
    git=1:2.43.0-1.1 \
    jq=1.7.1-2 \
    less=590-2 \
    libmagic1=1:5.46-1 \
    tshark=4.2.4-1~deb12u1 && \
    git clone https://github.com/CERT-Polska/hfinger.git && \
    apt-get autoremove -y git ca-certificates && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

WORKDIR /hfinger

RUN python3 -m venv $VIRTUAL_ENV && \
    pip3 install --no-cache-dir setuptools==73.0.1 && \
    python3 setup.py install && \
    rm -rf .git && \
    rm -rf /usr/local/share/man /var/cache/debconf/*-old

USER nobody

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD /hfinger/venv/bin/python -c "import hfinger" || exit 1

