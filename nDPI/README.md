# nDPI

Build a container with [nDPI](https://github.com/ntop/nDPI).

## Build container

```
docker build --tag=reuteras/ndpi .
```

## Usage

```
docker run -it --rm -v $PWD/pcap:/pcap --name ndpi reuteras/ndpi
```

Run `ndpiReader`:

```
ndpiReader -i <pcap file> -d
```

