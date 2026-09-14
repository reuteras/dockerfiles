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

## Quick Start

Run the automated quick-start script:

```sh
./quick-start.sh
```

This script:

1. Generates `.env` with random passwords
2. Starts Elasticsearch, Kibana, and Fleet Server
3. Creates a Fleet Server policy and service token
4. Creates a Linux endpoint policy with Elastic Defend and Auditd Manager
5. Generates an enrollment token for the endpoint policy
6. Waits for all services to be healthy
7. Prints the enrollment command for the Linux VM

### Enroll the Linux VM

Copy `setup-linux-vm.sh` to your Linux VM and run it with the enrollment token
printed by quick-start:

```sh
sudo ./setup-linux-vm.sh --mac-ip 192.168.1.50 --fleet-token YOUR_ENROLLMENT_TOKEN
```

This installs Elastic Agent from the official repository, enrolls with Fleet
Server, and starts the agent service.

### Install Prebuilt Detection Rules

In Kibana:

1. Go to **Security > Rules > Add Elastic rules**
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

## Stop or Reset the Lab

Stop containers while retaining data:

```sh
docker compose --profile fleet down
```

Delete all lab data and return to a clean state:

```sh
docker compose --profile fleet down --volumes
```

Deleting the volumes is irreversible.

## Manual Setup Reference

These steps are the manual equivalents of what the automated scripts do.
Use them if the scripts fail or if you need to customize the setup.

### Generate Environment File

```sh
./generate-env.sh
```

The script creates `.env` from `.env.example` with random passwords (mode
`600`). It refuses to overwrite an existing `.env`. To use different paths:

```sh
./generate-env.sh .env.example .env
```

### Start Elasticsearch and Kibana

```sh
docker compose up -d elasticsearch setup kibana
```

Wait for Kibana to become healthy, then open <http://localhost:5601>. Sign in
as `elastic` using `ELASTIC_PASSWORD` from `.env`.

### Configure Fleet Server

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

Verify Fleet Server is running:

```sh
curl http://localhost:8220/api/status
```

### Create Endpoint Policy

1. Go to **Management > Fleet > Agent policies**
2. Create a new policy for the Linux endpoint
3. Add integrations:
   - **Elastic Defend** - for threat detection
   - **Auditd Manager** - for syscall-level visibility

### Enroll a Linux VM Manually

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

## References

- [Linux local privilege escalation detection framework](https://www.elastic.co/security-labs/threat-command/linux-privilege-escalation-detection-framework)
- [Run Elastic Agent in a container](https://www.elastic.co/docs/reference/fleet/elastic-agent-container)
- [Install Elasticsearch with Docker](https://www.elastic.co/docs/deploy-manage/deploy/self-managed/install-elasticsearch-with-docker)
