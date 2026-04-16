FROM alpine:3.23

COPY upload.conf /etc/nginx/http.d/upload.conf

# hadolint ignore=DL3018
RUN apk update && \
    apk upgrade && \
    apk add --no-cache \
        nginx \
        nginx-mod-http-upload \
        nginx-mod-http-dav-ext && \
    sed -Ei s"/client_max_body_size 1m;/client_max_body_size 0;/" /etc/nginx/nginx.conf && \
    mkdir -p /usr/share/nginx/html/upload && \
    chown nginx /usr/share/nginx/html/upload && \
    chmod 755 /usr/share/nginx/html/upload

USER nginx

EXPOSE 80

STOPSIGNAL SIGQUIT

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:80/ || exit 1

CMD ["nginx", "-g", "daemon off;"]
