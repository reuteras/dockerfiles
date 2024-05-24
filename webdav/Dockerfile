FROM debian:12-slim
LABEL maintainer="Coding <code@ongoing.today>"

# hadolint ignore=DL3005,DL3008,DL3015
RUN apt-get update && \
    apt-get dist-upgrade -y && \
    apt-get install -y --no-install-recommends \
        apache2-utils \
        netcat-openbsd \
        nginx-extras && \
    apt-get clean && \
    apt-get autoremove -y && \
    rm -rf /var/lib/apt/lists/*

COPY webdav.conf /etc/nginx/conf.d/default.conf
COPY entrypoint.sh /

RUN rm /etc/nginx/sites-enabled/* && \
    mkdir -p "/webdav" && \
    chown www-data:www-data "/webdav" && \
    chmod +x entrypoint.sh

VOLUME /webdav
EXPOSE 80
ENTRYPOINT ["./entrypoint.sh"] 
CMD ["nginx", "-g", "daemon off;"]

HEALTHCHECK CMD nc -z localhost 80 || exit 1
