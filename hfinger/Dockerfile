FROM python:3.14-slim@sha256:9aaa474097d094040649f2162a627c0049b408f52138d980916788d80f04802f

LABEL maintainer="Coding <code@ongoing.today>"
ENV DEBIAN_FRONTEND noninteractive
ENV VIRTUAL_ENV=/hfinger/venv
ENV PATH="$VIRTUAL_ENV/bin:$PATH"

USER 0

# Install all OS dependencies for fully functional notebook server
# hadolint ignore=DL3008
RUN apt-get update && apt-get upgrade -yq && apt-get install -yq --no-install-recommends \
    ca-certificates \
    git \
    jq \
    less \
    libmagic1 \
    tshark && \
    git clone https://github.com/CERT-Polska/hfinger.git && \
    apt-get autoremove -y git ca-certificates && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

WORKDIR /hfinger

# hadolint ignore=DL3013
RUN python3 -m venv $VIRTUAL_ENV && \
    pip3 install --no-cache-dir setuptools && \
    python3 setup.py install && \
    rm -rf .git && \
    rm -rf /usr/local/share/man /var/cache/debconf/*-old

USER 65534

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD ["/bin/sh", "-c", "/hfinger/venv/bin/python -c \"import hfinger\" || exit 1"]
