# hadolint ignore=DL3007
FROM mitmproxy/mitmproxy:latest
WORKDIR /opt

# hadolint ignore=DL3003,DL3005,DL3008
RUN apt-get update && \
    apt-get dist-upgrade -yqq && \
    apt-get install -yq --no-install-recommends git && \
    git clone https://github.com/MISP/misp-guard.git && \
    cd misp-guard/src && \
    python -m pip install --no-cache-dir -r requirements.txt && \
    apt-get clean && apt-get autoremove -y && rm -rf /var/lib/apt/lists/*
