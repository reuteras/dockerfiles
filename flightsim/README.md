# flightsim

```text
A utility to safely generate malicious network traffic patterns and evaluate controls.
```

Read more about flightsim on [https://github.com/alphasoc/flightsim](https://github.com/alphasoc/flightsim).

## Build

Build the container:

    docker build --tag reuteras/flightsim .

## Usage

Use the container to get help:

    docker run --rm -it reuteras/flightsim:latest

Get help about the run command:

    docker run --rm -it reuteras/flightsim:latest flightsim run --help

## Alias

Add an alias for flightsim.

    alias flightsim='docker run --rm -it reuteras/flightsim:latest flightsim'
