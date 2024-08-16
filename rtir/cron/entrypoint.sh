#!/bin/bash

if [ ! -e "/etc/letsencrypt/rt-ready" ]; then
    sleep 5
fi

if [ ! -e "/etc/letsencrypt/live/$RT_HOSTNAME/privkey.pem" ]; then
    DNS_IP=""
    EXT_IP=""

    while [[ $EXT_IP == "" ]] ; do
        EXT_IP=$(curl -s https://icanhazip.com)
    done

    DNS_IP=$(dig @8.8.8.8 "$RT_HOSTNAME" | grep -v ';' | grep -v CNAME | grep A | awk '{print $5}')
    while [[ $EXT_IP != "$DNS_IP" ]]; do
        sleep 30
        DNS_IP=$(dig @8.8.8.8 "$RT_HOSTNAME" | grep -v ';' | grep -v CNAME | grep A | awk '{print $5}')
    done

    certbot certonly --standalone -m "$RT_SENDER" --agree-tos --no-eff-email -d "$RT_CERT_NAME" --force-renewal --non-interactive --http-01-port 8080
    cat "/etc/letsencrypt/live/$RT_HOSTNAME/cert.pem" "/etc/letsencrypt/live/$RT_HOSTNAME/privkey.pem" > \
        "/etc/letsencrypt/live/$RT_HOSTNAME/server.pem"
fi

exec "$@"
