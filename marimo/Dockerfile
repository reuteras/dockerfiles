FROM python:3.13-bookworm
LABEL maintainer="Coding <code@ongoing.today>"

# Install uv for fast package management
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/
ENV UV_SYSTEM_PYTHON=1

SHELL [ "/bin/bash", "-c" ]

RUN apt-get -y update && \
    apt-get -y install --no-install-recommends \
        git \
        vim && \
    uv venv .venv && \
    uv pip install pip --upgrade && \
    uv pip install marimo[sql] --upgrade

WORKDIR /marimo

# Create a non-root user and switch to it
RUN useradd -m app_user
USER app_user

#CMD [ "/.venv/bin/marimo", "edit", "--host", "0.0.0.0", "--no-token" ]
ENTRYPOINT ["/.venv/bin/marimo", "edit", "--host", "0.0.0.0"]
EXPOSE  2718
