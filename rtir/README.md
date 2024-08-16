# container-rt

[RT](https://www.bestpractical.com/rt/), or Request Tracker, is a issue tracking system. 

This repo will eventually replace my old [docker-rt](https://github.com/reuteras/docker-rt) repository. The goal of this repository is to runt most of the parts needed for RT in containers. One exception is the mail server that I have no plans to run in a container.

Warning! This is alpha quality and I only use it for testing and fun. Haven't used RT in production in 10+ years.

Currently build RT latest (5.0.x).

## Containers

### rt

Runs the RT instance.

### db

Postgres database.

To update database when a new version is installed:

    cd container-rt/
    docker-compose exec rt /bin/bash
    /opt/rt5/sbin/rt-setup-database --action upgrade --prompt-for-dba-password

### cron

Runs scripts to:

- Update certificate from [Let's Encrypt](https://letsencrypt.org/) stored in **cert** volume.
- Daily database backup. Store in **backup** volume mounted at */backup*.

## Usage


## Links

- [RT Documentation](https://docs.bestpractical.com/rt/5.0.1/index.html)

## TODO

- Instruction for adding plugins.
- [Full text indexing](https://docs.bestpractical.com/rt/5.0.1/full_text_indexing.html)
- Backups? https://docs.bestpractical.com/rt/5.0.1/system_administration/database.html
- [Automation](https://docs.bestpractical.com/rt/5.0.1/automating_rt.html) like running [rt-crontool](https://docs.bestpractical.com/rt/5.0.1/rt-crontool.html)?

## Changelog

- 2021-12-12: Add logging to lighttpd.
