#!/bin/bash
# Install zeek plugins

ZEEK_VER=$1
SPICY_VER=$2

SPICY_DIR=/usr/local/spicy-${SPICY_VER}
ZEEK_DIR=/usr/local/zeek-${ZEEK_VER}

export PATH=${ZEEK_DIR}/bin:${SPICY_DIR}/bin:${PATH}

zkg autoconfig --force

#  "https://github.com/0xl3x1/zeek-EternalSafety"
#  "https://github.com/corelight/CVE-2020-16898"
#  "https://github.com/corelight/SIGRed"
#  "https://github.com/corelight/zeek-community-id"
#  "https://github.com/corelight/zeek-xor-exe-plugin|master"
#  "https://github.com/corelight/zerologon"
#  "https://github.com/mitre-attack/bzar"
#  "https://github.com/precurse/zeek-httpattacks"
#  "https://github.com/salesforce/hassh"
#  "https://github.com/salesforce/ja3"
#  "https://github.com/zeek/spicy-analyzers"

ZKG_PACKAGE_NAMES=(
    "zeek/activecm/zeek-open-connections"
    "zeek-sniffpass"
    "zeek-community-id"
    "zeek/spicy-plugin"
    "zeek/spicy-analyzers"
)

for package in "${ZKG_PACKAGE_NAMES[@]}"; do
    zkg install --force --skiptests "${package}"
done

