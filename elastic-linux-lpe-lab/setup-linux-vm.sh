#!/usr/bin/env bash
#
# Setup script for Linux VM in elastic-linux-lpe-lab.
# Installs Elastic Agent and optionally upgrades to a specific kernel.
#
# Usage: ./setup-linux-vm.sh [--kernel KERNEL_VERSION] [--mac-ip MAC_IP]
#
# Examples:
#   ./setup-linux-vm.sh                    # Just install Elastic Agent
#   ./setup-linux-vm.sh --mac-ip 192.168.1.50
#   ./setup-linux-vm.sh --kernel 6.7 --mac-ip 192.168.1.50
#
# This script is meant to be run on the target Linux VM.

set -euo pipefail

KERNEL_VERSION=""
MAC_IP=""
FLEET_HOST="${FLEET_HOST:-}"
FLEET_ENROLLMENT_TOKEN="${FLEET_ENROLLMENT_TOKEN:-}"

print_help() {
  cat << 'EOF'
elastic-linux-lpe-lab: Linux VM setup script

Options:
  --kernel KERNEL_VERSION    Install specific kernel version (e.g., '6.7', '6.8.1')
  --mac-ip MAC_IP           Fleet Server IP (e.g., 192.168.1.50)
  --fleet-token TOKEN       Fleet enrollment token
  --help                    Show this help message

Environment variables:
  FLEET_HOST                Fleet Server IP or hostname
  FLEET_ENROLLMENT_TOKEN    Full enrollment token from Kibana
EOF
}

install_kernel() {
  local kernel_version="$1"

  printf 'Installing kernel version: %s\n' "$kernel_version"

  local arch
  arch=$(dpkg --print-architecture)
  if [[ "$arch" != "arm64" ]]; then
    printf 'Warning: This system is %s, not arm64. Kernel installation may differ.\n' "$arch"
  fi

  # Add backports repo if needed for newer kernels
  if ! grep -q 'debian.*backports' /etc/apt/sources.list /etc/apt/sources.list.d/* 2>/dev/null; then
    printf 'Adding Debian backports repository...\n'
    echo "deb http://deb.debian.org/debian $(lsb_release -cs)-backports main contrib non-free" \
      > /etc/apt/sources.list.d/backports.list
    apt-get update -qq
  fi

  # Install specific kernel version
  case "$kernel_version" in
    latest|current)
      printf 'Installing latest kernel...\n'
      apt-get install -y -qq linux-image-arm64
      ;;
    *)
      # Try to install specific version
      printf 'Searching for kernel version %s...\n' "$kernel_version"
      if apt-cache search "linux-image-$kernel_version" | grep -q "^linux-image"; then
        apt-get install -y -qq "linux-image-$kernel_version-arm64"
      elif apt-cache search "linux-image-arm64" | grep -q "$kernel_version"; then
        apt-get install -y -qq "linux-image-${kernel_version}-arm64"
      else
        printf 'Warning: Kernel version %s not found in repositories.\n' "$kernel_version"
        printf 'Installing from April 2026 snapshot requires:\n'
        printf '  1. Using snapshot.debian.org (snapshot.debian.org/archive/debian/YYYYMMDD/...)\n'
        printf '  2. Building from source: https://git.kernel.org\n'
        return 1
      fi
      ;;
  esac

  printf 'Kernel installation complete. Reboot required.\n'
}

install_elastic_agent() {
  # Install Elastic Agent from the official repository
  apt-get install -y -qq curl gpg

  printf 'Downloading Elastic Agent signing key...\n'
  # Same signing key (fingerprint 46095ACC8548582C1A2699A9D27D666CD88E42B4)
  # as GPG-KEY-elastic-agent, but re-certified in 2023 with a SHA-256
  # self-signature instead of the original 2013 SHA-1 one. Debian
  # trixie's default apt verifier (sqv) rejects SHA-1-bound keys as of
  # 2026-02-01, so GPG-KEY-elastic-agent fails "not bound" verification
  # there even though it signs this exact repository.
  curl -fsS https://artifacts.elastic.co/GPG-KEY-elasticsearch | gpg --dearmor \
    > /usr/share/keyrings/elastic-agents-archive-keyring.gpg

  printf 'Adding Elastic repository...\n'
  echo "deb [signed-by=/usr/share/keyrings/elastic-agents-archive-keyring.gpg] https://artifacts.elastic.co/packages/9.x/apt stable main" \
    > /etc/apt/sources.list.d/elastic-agents.list

  apt-get update -qq

  printf 'Installing Elastic Agent...\n'
  apt-get install -y -qq elastic-agent

  printf 'Elastic Agent installed successfully.\n'
}

enroll_agent() {
  local fleet_host="$1"
  local enrollment_token="$2"

  printf 'Enrolling agent with Fleet Server at %s...\n' "$fleet_host"

  /opt/elastic-agent/elastic-agent enroll \
    --url="http://${fleet_host}:8220" \
    --enrollment-token="$enrollment_token" \
    --insecure

  printf 'Agent enrolled. Starting service...\n'
  systemctl enable elastic-agent
  systemctl start elastic-agent

  printf 'Checking agent status...\n'
  systemctl status elastic-agent || true
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --kernel)
      KERNEL_VERSION="$2"
      shift 2
      ;;
    --mac-ip)
      MAC_IP="$2"
      shift 2
      ;;
    --fleet-token)
      FLEET_ENROLLMENT_TOKEN="$2"
      shift 2
      ;;
    --help)
      print_help
      exit 0
      ;;
    *)
      printf 'Unknown option: %s\n' "$1" >&2
      print_help
      exit 1
      ;;
  esac
done

printf '=== elastic-linux-lpe-lab: Linux VM Setup ===\n\n'

# Check if running as root
if [[ $EUID -ne 0 ]]; then
  printf 'This script must be run as root.\n' >&2
  exit 1
fi

# Detect OS
if [[ ! -f /etc/os-release ]]; then
  printf 'Error: Unable to detect OS.\n' >&2
  exit 1
fi

# shellcheck source=/dev/null
source /etc/os-release

# Ensure we're on Debian/Ubuntu
if [[ "$ID" != "debian" && "$ID" != "ubuntu" ]]; then
  printf 'Warning: This script is optimized for Debian/Ubuntu. Detected: %s\n' "$ID"
fi

printf 'Detected OS: %s %s (%s)\n' "$NAME" "$VERSION_ID" "$(dpkg --print-architecture)"

# Update package lists. Tolerate failure here: a previous run of this
# script may have left a broken third-party repo config (e.g. a bad
# Elastic signing key) in /etc/apt/sources.list.d, and that would
# otherwise block every subsequent run before install_elastic_agent()
# gets a chance to overwrite it with a working one. The apt-get update
# inside install_elastic_agent(), after that file is rewritten, is not
# tolerant and is the real gate on whether the install can proceed.
printf '\nUpdating package lists...\n'
if ! apt-get update -qq; then
  printf 'Warning: apt-get update reported errors (a previously configured repository may be broken); continuing.\n' >&2
fi

# Kernel installation
if [[ -n "$KERNEL_VERSION" ]]; then
  printf '\n=== Kernel Installation ===\n'
  install_kernel "$KERNEL_VERSION"
fi

# Install Elastic Agent
printf '\n=== Installing Elastic Agent ===\n'
install_elastic_agent

# Generate enrollment command
if [[ -n "$MAC_IP" && -n "$FLEET_ENROLLMENT_TOKEN" ]]; then
  printf '\n=== Enrolling with Fleet Server ===\n'
  enroll_agent "$MAC_IP" "$FLEET_ENROLLMENT_TOKEN"
fi

printf '\n=== Setup Complete ===\n'
printf 'Elastic Agent status: '
systemctl is-active elastic-agent || printf 'not running (enable with: sudo systemctl start elastic-agent)\n'

printf '\nNote: If you did not provide --mac-ip and --fleet-token,\n'
printf 'you can enroll the agent later using:\n'
printf '  sudo elastic-agent enroll --url http://YOUR_MAC_IP:8220 --enrollment-token YOUR_TOKEN --insecure\n'
