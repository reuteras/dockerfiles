FROM alpine
COPY upload.conf /etc/nginx/http.d/upload.conf
RUN apk update && \
    apk upgrade && \
    apk add --no-cache nginx nginx-mod-http-upload && \
    sed -Ei s"/client_max_body_size 1m;/client_max_body_size 0;/" /etc/nginx/nginx.conf && \
    mkdir -p /usr/share/nginx/html/upload && \
    chown nginx /usr/share/nginx/html/upload && \
    chmod 755 /usr/share/nginx/html/upload

EXPOSE 80

STOPSIGNAL SIGQUIT

CMD ["nginx", "-g", "daemon off;"]
