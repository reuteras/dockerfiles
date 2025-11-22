# nDPI

Build a container with [nDPI](https://github.com/ntop/nDPI).

## Build container

```bash
docker build --tag=reuteras/ndpi .
```

## Usage

```bash
docker run -it --rm -v $PWD/pcap:/pcap --name ndpi reuteras/ndpi
```

Run `ndpiReader`:

```bash
ndpiReader -i <pcap file> -d
```

