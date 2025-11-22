FROM mitmproxy/mitmproxy:11.0.0

WORKDIR /opt

RUN apt-get update && \
    apt-get dist-upgrade -yqq && \
    apt-get install -yq --no-install-recommends git=1:2.43.0-1.1 && \
    git clone https://github.com/MISP/misp-guard.git && \
    cd misp-guard/src && \
    python -m pip install --no-cache-dir -r requirements.txt && \
    apt-get clean && apt-get autoremove -y && rm -rf /var/lib/apt/lists/*

USER nobody

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD python -c "import misp_guard" || exit 1
