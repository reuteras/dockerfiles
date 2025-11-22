#!/bin/bash

if [[ -n "$USERNAME" ]] && [[ -n "$PASSWORD" ]]; then
	htpasswd -bc /etc/nginx/htpasswd "$USERNAME" "$PASSWORD"
	echo Done.
else
	exit 1
fi

exec "$@"
