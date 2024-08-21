#!/bin/sh

export PGPASSWORD=$POSTGRES_PASSWORD

KEEP_DAYS=14

OUTPUT="/backup/rt-$(date +%Y%m%d).sql.gz"

( pg_dump -h "$RT_DB_HOST" -U "$POSTGRES_USER" "$RT_DB_NAME" --table=sessions --schema-only; \
    pg_dump -h "$RT_DB_HOST" -U "$POSTGRES_USER" "$RT_DB_NAME" --exclude-table=sessions ) | \
    gzip > "$OUTPUT"

chown "$CONTAINER_USER:$CONTAINER_USER" "$OUTPUT"

find /backup -type f -name '*.gz' -mtime +$KEEP_DAYS -delete
