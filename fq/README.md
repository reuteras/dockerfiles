# fq

```text
jq for binary formats - tool, language and decoders for working with binary and text formatsi
```

Read more about fq on [https://github.com/wader/fq](https://github.com/wader/fq).

## Build

Build the container:

```bash
docker build --tag reuteras/fq .
```

## Usage

Use the container:

```bash
docker run --rm -it -v "$(pwd)"/files:/files reuteras/fq:latest d files/bash
```

If you pipe the out put to **less** you have to add -rU.

```bash
docker run --rm -it -v "$(pwd)"/files:/files reuteras/fq:latest d files/bash | less -rU
```


## Alias

Add an alias for fq.

```bash
alias fq='docker run --rm -it -v "$(pwd)"/files:/files reuteras/fq:latest'
```
