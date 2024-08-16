FROM alpine:3.20
LABEL maintainer="Coding <code@ongoing.today>"

ENV SCRIPT_ROOT=/opt/rt
ENV USER=rt-service
ENV UID=1000
ENV GID=1000

RUN apk add --no-cache \
        bind-tools \
        curl \
        dcron \
        postgresql-client && \
    mkdir -p ${SCRIPT_ROOT} && \
    addgroup \
        --gid "$GID" \
        "$USER" && \
    adduser \
        --disabled-password \
        --gecos "" \
        --home "$(pwd)" \
        --ingroup "$USER" \
        --no-create-home \
        --uid "$UID" \
        "$USER" && \
    mkdir -p /var/log/letsencrypt /var/lib/letsencrypt && \
    chown -R ${USER}:${USER} /var/log/letsencrypt /var/lib/letsencrypt && \
    mkdir /backup && \
    chown ${USER}:${USER} /backup

COPY dcron.sh ${SCRIPT_ROOT}
COPY pg_backup.sh /etc/periodic/daily/pg_backup

RUN chmod 0755 ${SCRIPT_ROOT}/dcron.sh && \
    chmod 0755 /usr/sbin/crond

CMD ["/opt/rt/dcron.sh", "-f"]
