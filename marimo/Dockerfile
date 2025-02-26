FROM python:3.13-bookworm
LABEL maintainer="Coding <code@ongoing.today>"

# Install uv for fast package management
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/

RUN apt-get -y update && \
    apt-get -y install --no-install-recommends \
        git \
        vim && \
    useradd -m marimo && \
    mkdir /data && \
    chown marimo:marimo /data

WORKDIR /home/marimo
USER marimo

RUN uv venv --seed .venv && \
    . /home/marimo/.venv/bin/activate && \
    python3 -m pip install -U pip && \
    python3 -m pip install -U marimo

WORKDIR /data

ENTRYPOINT ["/home/marimo/.venv/bin/marimo", "edit", "--sandbox", "--host", "0.0.0.0", "--no-token", "app.py" ]
EXPOSE  2718
