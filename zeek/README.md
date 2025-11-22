# container-zeek

Build for arm64 and amd64.

Switch back to building from source and using the LTS version to be able to use more zkg packages.

## Build

    docker build --tag=reuteras/container-zeek .

## Run

    docker run -it --rm -v "$PWD"/pcap:/pcap:ro -v "$PWD"/output:/output reuteras/container-zeek /bin/bash
