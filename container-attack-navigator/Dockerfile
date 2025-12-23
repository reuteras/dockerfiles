#checkov:skip=CKV_DOCKER_2
#checkov:skip=CKV_DOCKER_3
FROM node:24-bookworm as build-env

LABEL maintainer="Coding <code@ongoing.today>"

ENV NODE_OPTIONS=--openssl-legacy-provider

WORKDIR /src

COPY offline.sh /offline.sh

RUN apt-get update --fix-missing && \
    apt-get install -qqy --no-install-recommends \
        ca-certificates \
        git \
        wget && \
    git clone https://github.com/mitre-attack/attack-navigator.git && \
    mv attack-navigator/nav-app . && \
    mkdir layers && \
    cp attack-navigator/layers/*.md /src/layers/ && \
    cp attack-navigator/*.md /src/ && \
    cd nav-app/src/assets && \
    sh /offline.sh && \
    cd ../.. && \
    npm install --force --unsafe-perm --legacy-peer-deps && \
    npm install --force -g @angular/cli@11 && \
    ng build --output-path=/tmp/output && \
    rm -rf /var/lib/apt/lists/*

# Build final container to serve static content.
FROM nginx:mainline-alpine
LABEL maintainer="Coding <code@ongoing.today>"
COPY --from=build-env /tmp/output /usr/share/nginx/html

