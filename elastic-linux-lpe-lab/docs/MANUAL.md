# Manual Setup Reference

These steps are the manual equivalents of what the automated scripts do.
Use them if the scripts fail or if you need to customize the setup.

## Generate Environment File

```sh
./generate-env.sh
```

The script creates `.env` from `.env.example` with random passwords (mode
`600`). It refuses to overwrite an existing `.env`. To use different paths:

```sh
./generate-env.sh .env.example .env
```

## Start Elasticsearch and Kibana

```sh
docker compose up -d elasticsearch setup kibana
```

Wait for Kibana to become healthy, then open <http://localhost:5601>. Sign in
as `elastic` using `ELASTIC_PASSWORD` from `.env`.

## Configure Fleet Server

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

## Create Endpoint Policy

1. Go to **Management > Fleet > Agent policies**
2. Create a new policy for the Linux endpoint
3. Add integrations:
   - **Elastic Defend** - for threat detection
   - **Auditd Manager** - for syscall-level visibility

## Enroll a Linux VM Manually

Generate the enrollment command from Kibana, replacing the Fleet URL with
the host address visible to the VM. Leave the systemd service running — after
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
  --url=http://HOST-IP-ADDRESS:8220 \
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
