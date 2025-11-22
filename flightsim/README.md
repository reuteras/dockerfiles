# flightsim

```text
A utility to safely generate malicious network traffic patterns and evaluate controls.
```

Read more about flightsim on [https://github.com/alphasoc/flightsim](https://github.com/alphasoc/flightsim).

## Build

Build the container:

```bash
docker build --tag reuteras/flightsim .
```

## Usage

Use the container to get help:

```bash
docker run --rm -it reuteras/flightsim:latest
```

Get help about the run command:

```bash
docker run --rm -it reuteras/flightsim:latest flightsim run --help
```

## Alias

Add an alias for flightsim.

```bash
alias flightsim='docker run --rm -it reuteras/flightsim:latest flightsim'
```
