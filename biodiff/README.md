# biodiff

A container for [biodiff](https://github.com/8051Enthusiast/biodiff).

## Build

Build the container:

    docker build --tag reuteras/biodiff .

## Usage

Use the container:

    docker run --rm -it -v "$(pwd)":/diff reuteras/biodiff
    root@8289a55ce27e:/diff# biodiff file1 file2


## Alias

Add an alias for biodiff.

    alias biodiff='docker run --rm -ti -v "$(pwd)":/diff --name biodiff biodiff biodiff'

Then you can run the following in current directory (stupid example).

    biodiff README.md Dockerfile
