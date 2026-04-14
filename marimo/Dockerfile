FROM python:3.14-bookworm

LABEL maintainer="Coding <code@ongoing.today>"

# Install uv for fast package management
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/

# hadolint ignore=DL3008
RUN apt-get -y update && \
    apt-get -y install --no-install-recommends \
        git \
        vim && \
    useradd -m marimo && \
    mkdir /data && \
    chown marimo:marimo /data && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /home/marimo
USER marimo

# hadolint ignore=DL3013
RUN uv venv --seed .venv && \
    . /home/marimo/.venv/bin/activate && \
    python3 -m pip install --no-cache-dir pip && \
    python3 -m pip install --no-cache-dir marimo

WORKDIR /data

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD /home/marimo/.venv/bin/python -c "import marimo" || exit 1

ENTRYPOINT ["/home/marimo/.venv/bin/marimo", "edit", "--sandbox", "--host", "0.0.0.0", "--no-token", "app.py" ]
EXPOSE 2718
