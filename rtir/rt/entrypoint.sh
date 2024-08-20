#!/bin/bash

for variable in POSTGRES_USER POSTGRES_PASSWORD RT_DB_HOST RT_USER RT_PASSWORD \
    RT_DB_NAME RT_DB_PORT RT_HOSTNAME RT_RELAYHOST RT_SENDER RT_DOMAIN  \
    RT_CERT_NAME CONTAINER_USER; do
    if [[ -z  "${!variable}" ]]; then
        echo >&2 "You must specify \$$variable."
        exit 1
    fi
done

if ! grep "$RT_RELAYHOST" /etc/msmtprc > /dev/null ; then
    cp /etc/msmtprc /tmp/msmtprc
    sed -i -e "s=RT_RELAYHOST=$RT_RELAYHOST=" /tmp/msmtprc
    sed -i -e "s=RT_SENDER=$RT_SENDER=" /tmp/msmtprc
    sed -i -e "s=RT_DOMAIN=$RT_DOMAIN=" /tmp/msmtprc
    cat /tmp/msmtprc > /etc/msmtprc
    rm -f /tmp/msmtprc
fi

while ! pg_isready -q -h "$RT_DB_HOST" ; do
    echo "Waiting for database on $RT_DB_HOST to be ready."
    sleep 3
done

if ! PGPASSWORD="$RT_PASSWORD" psql -h "$RT_DB_HOST" -U "$RT_USER" -lqt | cut -d \| -f 1 | grep -qw "$RT_DB_NAME" ; then
    echo "Setup database"
    /opt/rt5/sbin/rt-setup-database --dba="$POSTGRES_USER" --dba-password="$POSTGRES_PASSWORD" --action init
    cd /tmp/rtir/RT* || exit
    echo "$POSTGRES_PASSWORD" | perl -Ilib -I"/opt/rt5/local/lib" -I"/opt/rt5/lib" -Iinc -MModule::Install::RTx::Runtime -e"RTxDatabase(qw(insert 'RT::IR' $(RTIR_VERSION)))"
    echo "Database setup done."
else
    echo "Check if database needs an upgrade."
    # /opt/rt5/sbin/rt-setup-database --action upgrade --dba="$POSTGRES_USER" --dba-password="$POSTGRES_PASSWORD"
fi

exec "$@"
