# Elastic Linux LPE lab

Minimal Elastic Security control plane for testing Linux local privilege
escalation detections from the Elastic Security Labs article
[Linux Detection Engineering - Local Privilege Escalation](https://www.elastic.co/security-labs/threat-command/linux-privilege-escalation-detection-framework).

The server components run in Docker Desktop on an Apple Silicon Mac. Elastic
Agent, Elastic Defend, and Auditd Manager run inside a disposable Linux VM so
they observe the VM rather than the Docker container.

## Architecture

Tested version of Elastic tools are can be found in .env.examle.

- Elasticsearch and Kibana on the Mac
- Fleet Server on the Mac, exposed to the lab VM on TCP 8220
- One disposable Linux VM with Elastic Agent
- Trial license (30 days, full functionality), activated automatically by
  `quick-start.sh`
- Persistent Docker volumes for Elasticsearch and Fleet state

Kibana listens only on the Mac loopback interface. Elasticsearch and Fleet
Server are both exposed to the lab network (TCP 9200 and 8220) so agents —
Fleet Server's own monitoring, and the Linux VM's Elastic Defend/Auditd
Manager data — can actually ship data to Elasticsearch; `quick-start.sh`
points Fleet's default output at the Mac's LAN address for this. Both use
plain HTTP with no TLS for this simple isolated lab setup, so do not expose
either port to an untrusted network.

Installing the Elastic Defend and Auditd Manager integrations makes Kibana
fetch packages from the public Elastic Package Registry (EPR), which
intermittently rate-limits IPv4 while leaving IPv6 unaffected. `quick-start.sh`
checks whether this host has a working outbound IPv6 route to EPR and, only if
so, tells Kibana to prefer it; on an IPv4-only network it leaves Kibana's
default behavior untouched. Either way, both integration installs retry with
backoff before giving up.

## Requirements

- Apple Silicon Mac
- Docker Desktop, running, with ports 9200, 5601, and 8220 free
- A disposable Linux VM reachable from the Mac
- `openssl` for generating random secrets
- `curl` for automated Fleet Server setup
- `lsof` for the port check in `quick-start.sh`

An ARM64 VM is the fastest option on Apple Silicon. Some public kernel exploit
PoCs may assume x86_64; use an emulated x86_64 VM when a particular PoC does
not support ARM64.

## Quick Start

Run the automated quick-start script:

```sh
./quick-start.sh
```

This script:

1. Checks that Docker is running and that ports 9200, 5601, and 8220 are free
2. Generates `.env` with random passwords
3. Starts Elasticsearch and Kibana, and waits for both to be healthy
4. Activates a 30-day trial license for full functionality
5. Creates a Fleet Server policy and service token, then starts Fleet Server
6. Creates a Linux endpoint policy with Elastic Defend and Auditd Manager
7. Generates an enrollment token for the endpoint policy
8. Prints the enrollment command for the Linux VM

Run `./quick-start.sh clean` to stop and remove the lab's containers, network,
and volumes, and delete the generated `.env` (add `-y` to skip the
confirmation prompt).

### Enroll the Linux VM

Clone the repo and then run `setup-linux-vm.sh` in your Linux VM with the enrollment token
printed by quick-start:

```sh
git clone https://github.com/reuteras/dockerfiles.git
cd dockerfiles/elastic-linux-lpe-lab
sudo ./setup-linux-vm.sh --mac-ip 192.168.X.Y --fleet-token YOUR_ENROLLMENT_TOKEN
```

This installs Elastic Agent from the official repository, enrolls with Fleet
Server, and starts the agent service. It also installs `auditctl` (from the
`auditd` package, for verifying rules with `sudo auditctl -l`) without
leaving the system's own `auditd` service running, since it would otherwise
fight Auditd Manager for the audit netlink socket.

### Install Prebuilt Detection Rules

In Kibana:

1. Go to **Security > Rules > Add Elastic rules**
2. Install the Elastic prebuilt detection rules
3. Enable rules by filtering on tags (you must enable the rules and not just install them):
   - `OS: Linux`
   - `Tactic: Privilege Escalation`

Auditd Manager provides the syscall-level visibility used by the research,
including `socket`, `splice`, `bind`, and `execve`. `quick-start.sh` already
configures the `socket`/`splice`/`bind` rules from the article's linked
[Copy Fail and DirtyFrag research](https://www.elastic.co/security-labs/copy-fail-dirtyfrag-linux-page-bugs-in-the-wild)
on the Auditd Manager integration it creates.

## Install a Vulnerable Kernel (DSA-6162-1)

DSA-6162-1 addresses AppArmor privilege-escalation vulnerabilities fixed in
linux 6.12.74-2; the vulnerable 6.12.74-1 has since been superseded in the
live trixie-security archive, so it's no longer installable with a plain
`apt install`. Pin a snapshot.debian.org archive from just before the fix
(verified against the actual package index) instead. `check-valid-until=no`
is required: snapshot.debian.org's Release files carry a short `Valid-Until`
(days, not the months this snapshot will realistically age to), and apt
refuses a repository past that date by default; the option is scoped to only
this one source, not a global downgrade of apt's freshness checks:

```sh
echo 'deb [trusted=yes check-valid-until=no] http://snapshot.debian.org/archive/debian-security/20260312T211821Z/ trixie-security main' \
  | sudo tee /etc/apt/sources.list.d/snapshot-dsa-6162.list
printf 'Package: *\nPin: origin snapshot.debian.org\nPin-Priority: 1\n' \
  | sudo tee /etc/apt/preferences.d/snapshot-dsa-6162.pref
sudo apt update
sudo apt install -y linux-image-6.12.74+deb13-arm64=6.12.74-1
sudo reboot
```

The pin file keeps this source from ever being picked for anything but this
one, explicitly version-pinned package. Once you've booted the vulnerable
kernel, the snapshot source is no longer needed and can be removed:

```sh
sudo rm /etc/apt/sources.list.d/snapshot-dsa-6162.list /etc/apt/preferences.d/snapshot-dsa-6162.pref
sudo apt update
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

Delete all lab data and return to a clean state, including the generated
`.env`:

```sh
./quick-start.sh clean
```

Or do it manually, which keeps `.env` in place:

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
the Mac address visible to the VM. Leave the systemd service running — after
writing the new config, `enroll` hot-reloads the already-running daemon over
a control socket under `--path.home`, so stopping it first just makes that
reload retry against a socket that will never reappear. Pass `--path.config`
explicitly too, since without it `enroll` looks for `elastic-agent.yml`
directly under `--path.home` instead of the split `/etc/elastic-agent`
location the systemd service actually reads from:

```sh
sudo /usr/share/elastic-agent/bin/elastic-agent enroll \
  --path.home=/var/lib/elastic-agent \
  --path.config=/etc/elastic-agent \
  --url=http://MAC-IP-ADDRESS:8220 \
  --enrollment-token=YOUR_TOKEN \
  --insecure
```

Then restart the agent so it's definitely running the new config:

```sh
sudo systemctl enable elastic-agent
sudo systemctl restart elastic-agent
```

The `--insecure` flag is required because this isolated lab uses HTTP for
Fleet Server.

## References

- [Linux local privilege escalation detection framework](https://www.elastic.co/security-labs/threat-command/linux-privilege-escalation-detection-framework)
- [Run Elastic Agent in a container](https://www.elastic.co/docs/reference/fleet/elastic-agent-container)
- [Install Elasticsearch with Docker](https://www.elastic.co/docs/deploy-manage/deploy/self-managed/install-elasticsearch-with-docker)
