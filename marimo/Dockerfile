FROM python:3.13-bookworm

LABEL maintainer="Coding <code@ongoing.today>"

# Install uv for fast package management
COPY --from=ghcr.io/astral-sh/uv:0.5.6 /uv /uvx /bin/

RUN apt-get -y update && \
    apt-get -y install --no-install-recommends \
        git=1:2.43.0-1.1 \
        vim=2:9.1.0416-1+deb12u1 && \
    useradd -m marimo && \
    mkdir /data && \
    chown marimo:marimo /data && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /home/marimo
USER marimo

RUN uv venv --seed .venv && \
    . /home/marimo/.venv/bin/activate && \
    python3 -m pip install --no-cache-dir pip==24.3.1 && \
    python3 -m pip install --no-cache-dir marimo==0.10.8

WORKDIR /data

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD /home/marimo/.venv/bin/python -c "import marimo" || exit 1

ENTRYPOINT ["/home/marimo/.venv/bin/marimo", "edit", "--sandbox", "--host", "0.0.0.0", "--no-token", "app.py" ]
EXPOSE 2718
