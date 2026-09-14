# Elastic Linux LPE lab

Minimal Elastic Security control plane for testing Linux local privilege
escalation detections from the Elastic Security Labs article
[Linux Detection Engineering - Local Privilege Escalation](https://www.elastic.co/security-labs/threat-command/linux-privilege-escalation-detection-framework).

The server components run in Docker Desktop on an Apple Silicon Mac. Elastic
Agent, Elastic Defend, and Auditd Manager run inside a disposable Linux VM so
they observe the VM rather than the Docker container.

## Architecture

- Elasticsearch 9.5.3 and Kibana 9.5.3 on the Mac
- Fleet Server 9.5.3 on the Mac, exposed to the lab VM on TCP 8220
- One disposable Linux VM with Elastic Agent
- Basic license by default
- Persistent Docker volumes for Elasticsearch and Fleet state

Elasticsearch and Kibana listen only on the Mac loopback interface. Fleet
Server uses HTTP for a simple isolated lab setup, so do not expose port 8220 to
an untrusted network.

## Requirements

- Apple Silicon Mac
- Docker Desktop with at least 6 GB of memory available
- A disposable Linux VM reachable from the Mac
- `openssl` for generating random secrets
- `curl` for automated Fleet Server setup

An ARM64 VM is the fastest option on Apple Silicon. Some public kernel exploit
PoCs may assume x86_64; use an emulated x86_64 VM when a particular PoC does
not support ARM64.

## Quick Start (Automated)

For fastest setup, use the automated quick-start script:

```sh
./quick-start.sh
```

This script:
1. Generates `.env` with random passwords
2. Starts Elasticsearch, Kibana, and Fleet Server
3. Automatically creates Fleet Server policy and service token
4. Waits for all services to be healthy

After quick-start completes, continue with **Create an Endpoint Policy** below.

## Manual Setup

### Start Elasticsearch and Kibana

Generate the local configuration and random passwords from `.env.example`:

```sh
./generate-env.sh
```

The script refuses to overwrite an existing `.env` and creates it with mode
`600`. To use different input and output paths, pass them as arguments:

```sh
./generate-env.sh .env.example .env
```

Do not commit `.env`. Save its generated passwords in your password manager,
then start the control plane:

```sh
docker compose up -d elasticsearch setup kibana
```

Wait for Kibana to become healthy, then open <http://localhost:5601>. Sign in
as `elastic` using `ELASTIC_PASSWORD` from `.env`.

## Configure and start Fleet Server

### Automated Setup (Recommended)

If quick-start was not used, automate Fleet Server setup:

```sh
./setup-fleet.sh
```

This script creates a Fleet Server policy and service token, updates `.env`,
and displays the next steps. Then start Fleet Server:

```sh
docker compose --profile fleet up -d
```

### Manual Fleet Configuration

If automated setup fails or you prefer manual configuration:

1. Open **Management > Fleet** in Kibana and complete initial setup.
2. Add a Fleet Server using the advanced deployment option.
3. Create or select the Fleet Server policy.
4. Generate a service token and copy it.
5. Put the generated service token in `FLEET_SERVER_SERVICE_TOKEN` in `.env`.
6. Put the policy ID in `FLEET_SERVER_POLICY_ID` in `.env`.
7. Start Fleet Server:

```sh
docker compose --profile fleet up -d
```

### Verify Fleet Server Status

```sh
curl http://localhost:8220/api/status
docker compose ps
```

## Setup the Linux Endpoint

### Create Endpoint Policy in Kibana

1. Go to **Management > Fleet > Agent policies**
2. Create a new policy for the Linux endpoint
3. Add integrations:
   - **Elastic Defend** - for threat detection
   - **Auditd Manager** - for syscall-level visibility

### Enroll the Linux VM

### Automated Enrollment (Recommended)

Copy `setup-linux-vm.sh` to your Linux VM and run it:

```sh
sudo ./setup-linux-vm.sh --mac-ip 192.168.1.50 --fleet-token YOUR_ENROLLMENT_TOKEN
```

This script:
- Installs Elastic Agent from the official repository
- Enrolls with Fleet Server automatically
- Enables and starts the agent service

### Manual Enrollment

Generate the enrollment command from Kibana, replacing the Fleet URL with
the Mac address visible to the VM:

```sh
sudo elastic-agent enroll \
  --url=http://MAC-IP-ADDRESS:8220 \
  --enrollment-token=YOUR_TOKEN \
  --insecure
```

Then start the agent:

```sh
sudo systemctl enable elastic-agent
sudo systemctl start elastic-agent
```

The `--insecure` flag is required because this isolated lab uses HTTP for
Fleet Server.

### Install Prebuilt Detection Rules

In Kibana:

1. Go to **Security > Threat Intelligence > Prebuilt rules**
2. Install the Elastic prebuilt detection rules
3. Enable rules by filtering on tags:
   - `OS: Linux`
   - `Tactic: Privilege Escalation`

Auditd Manager provides the syscall-level visibility used by the research,
including `socket`, `splice`, `bind`, and `execve`. Follow the article's linked
audit rules for the specific page-cache tests.

## Install a Vulnerable Kernel (DSA-6162-1)

DSA-6162-1 addresses AppArmor privilege-escalation vulnerabilities fixed in
linux 6.12.74-2. To install the pre-fix kernel on an arm64 Debian Trixie VM:

```sh
sudo apt update
sudo apt install -y linux-image-6.12.74-1-arm64
sudo reboot
```

After reboot, verify with `uname -r` and restart the agent if needed:

```sh
sudo systemctl restart elastic-agent
```

## Stop or reset the lab

Stop containers while retaining data:

```sh
docker compose --profile fleet down
```

Delete all lab data and return to a clean state:

```sh
docker compose --profile fleet down --volumes
```

Deleting the volumes is irreversible.

## References

- [Linux local privilege escalation detection framework](https://www.elastic.co/security-labs/threat-command/linux-privilege-escalation-detection-framework)
- [Run Elastic Agent in a container](https://www.elastic.co/docs/reference/fleet/elastic-agent-container)
- [Install Elasticsearch with Docker](https://www.elastic.co/docs/deploy-manage/deploy/self-managed/install-elasticsearch-with-docker)
