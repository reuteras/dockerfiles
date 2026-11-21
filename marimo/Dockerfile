# Python 3.14: marimo[recommended] pulls loro, whose PyO3 does not support 3.15 yet
FROM python:3.14-trixie@sha256:8a6b0a0ed63fb9d4ea59ee320591109f14205bbe7a787c51d9f72ad2a2f7e89c

LABEL maintainer="Coding <code@ongoing.today>"

# Install uv for fast package management
COPY --from=ghcr.io/astral-sh/uv:0.13.9@sha256:d3b601f0c7b118bc1753febf7c41cc80981df678445e0254284eecf84db79a7d /uv /uvx /bin/

# hadolint ignore=DL3008
RUN apt-get -y update && \
    apt-get -y upgrade && \
    apt-get -y install --no-install-recommends \
        git \
        vim && \
    useradd -m -u 1000 marimo && \
    mkdir /data && \
    chown marimo:marimo /data && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /home/marimo
USER 1000

# hadolint ignore=DL3013,SC1091
RUN uv venv --seed .venv && \
    . /home/marimo/.venv/bin/activate && \
    python3 -m pip install --no-cache-dir pip && \
    python3 -m pip install --no-cache-dir "marimo[recommended]"

WORKDIR /data

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD ["/bin/sh", "-c", "/home/marimo/.venv/bin/python -c \"import marimo\" || exit 1"]

ENTRYPOINT ["/home/marimo/.venv/bin/marimo", "edit", "--sandbox", "--host", "0.0.0.0", "--no-token", "app.py" ]
EXPOSE 2718
