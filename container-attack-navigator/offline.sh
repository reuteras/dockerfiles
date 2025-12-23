#!/bin/bash

grep '"data":' config.json | grep -oE "https:.*json" > urls

# shellcheck disable=SC2013
for url in $(cat urls); do
    path=$(echo "${url}" | sed -E "s/.*26CK-//" | sed -E "s#/[^/]+\.json##")
    name=$(echo "${url}" | sed -E "s/.*26CK-//")
    mkdir -p "${path}"
    wget -q -O "${name}" "${url}"
done
rm -f urls

sed -i "s#https:.*26CK-#assets/#" config.json
