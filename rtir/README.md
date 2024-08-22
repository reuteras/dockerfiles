# container-rt with RTIR

[RT](https://www.bestpractical.com/rt/), or Request Tracker, is a issue tracking system and this container also includes [RTIR](https://www.bestpractical.com/rtir/).

The goal of this repository is to runt most of the parts needed for RT and RTIR in containers with the exception of a mail server that I have no plans to run in a container.

Warning! This is alpha quality and I only use it for testing and fun. Haven't used RT in production in 15+ years.

## Containers

### rt

Runs the RT instance with RTIR.

### db

Postgres database.

To update database when a new version is installed:

    cd container-rt/
    docker-compose exec rt /bin/bash
    /opt/rt5/sbin/rt-setup-database --action upgrade --prompt-for-dba-password

### caddy

Front server that automatically retrieves a certificate from [Let's Encrypt](https://letsencrypt.org/).

## Usage


## Links

- [RT Documentation](https://docs.bestpractical.com/rt/5.0.7/index.html)

## TODO

- Instruction for adding plugins.
- [Full text indexing](https://docs.bestpractical.com/rt/5.0.7/full_text_indexing.html)
- Backups? https://docs.bestpractical.com/rt/5.0.7/system_administration/database.html
- [Automation](https://docs.bestpractical.com/rt/5.0.7/automating_rt.html) like running [rt-crontool](https://docs.bestpractical.com/rt/5.0.7/rt-crontool.html)?

