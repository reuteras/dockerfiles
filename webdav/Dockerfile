FROM debian:bullseye-slim

LABEL maintainer="Coding <code@ongoing.today>"

# hadolint ignore=DL3008,DL3009
RUN apt-get update && \
    apt-get dist-upgrade -y && \
    apt-get install -y --no-install-recommends \
        apache2-utils \
        netcat-openbsd \
        nginx-extras && \
    apt-get clean && \
    apt-get autoremove -y

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
