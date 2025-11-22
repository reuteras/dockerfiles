FROM alpine:3.21

COPY upload.conf /etc/nginx/http.d/upload.conf

RUN apk update && \
    apk upgrade && \
    apk add --no-cache nginx=1.26.2-r0 nginx-mod-http-upload=1.26.2-r0 nginx-mod-http-dav-ext=1.26.2-r0 && \
    sed -Ei s"/client_max_body_size 1m;/client_max_body_size 0;/" /etc/nginx/nginx.conf && \
    mkdir -p /usr/share/nginx/html/upload && \
    chown nginx /usr/share/nginx/html/upload && \
    chmod 755 /usr/share/nginx/html/upload && \
    rm -rf /var/cache/apk/*

USER nginx

EXPOSE 80

STOPSIGNAL SIGQUIT

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:80/ || exit 1

CMD ["nginx", "-g", "daemon off;"]
