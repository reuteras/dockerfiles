# MITRE ATT&CK® Navigator in a container

![Linter](https://github.com/reuteras/container-attack-navigator/workflows/Linter/badge.svg)

My Docker container for offline use of [MITRE ATT&CK® Navigator](https://github.com/mitre-attack/attack-navigator). This container is inspired by [vanimpe.eu](https://www.vanimpe.eu/2020/07/06/install-mitre-attck-navigator-in-an-isolated-environment/).

## Usage

To run the container from Docker Hub:

    docker run --rm -p 80:80 reuteras/container-attack-navigator

## Build and run

If you prefer to build locally:

    docker build --tag=attack-navigator .
    docker run --rm -p 80:80 attack-navigator
