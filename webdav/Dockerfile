FROM debian:bookworm-20250109-slim

LABEL maintainer="Coding <code@ongoing.today>"

RUN apt-get update && \
    apt-get dist-upgrade -y && \
    apt-get install -y --no-install-recommends \
        apache2-utils=2.4.59-1 \
        netcat-openbsd=1.10-47 \
        nginx-extras=1.26.0-1+0~20240624.11+debian~bookworm+1~bpo12+1 && \
    apt-get clean && \
    apt-get autoremove -y && \
    rm -rf /var/lib/apt/lists/*

COPY webdav.conf /etc/nginx/conf.d/default.conf
COPY entrypoint.sh /

RUN rm /etc/nginx/sites-enabled/* && \
    mkdir -p "/webdav" && \
    chown www-data:www-data "/webdav" && \
    chmod +x /entrypoint.sh

VOLUME /webdav
EXPOSE 80

USER www-data

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD nc -z localhost 80 || exit 1

ENTRYPOINT ["/entrypoint.sh"]
CMD ["nginx", "-g", "daemon off;"]
