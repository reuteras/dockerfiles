# webdav

nginx configured as a WebDAV server with basic auth, based on Debian.

## Configure

Copy `.env-default` to `.env` and set `USERNAME` and `PASSWORD` to whatever
credentials you want the WebDAV server to require.

    cp .env-default .env

## Build and run

Build and start the container with Docker Compose:

    docker compose up -d

Files are stored in the `./webdav` directory, which is mounted as a volume
in the container, and the server is published on
[http://127.0.0.1:8081](http://127.0.0.1:8081).

## Usage

Upload a file with curl:

    curl -u user:password1 --upload-file upload.conf http://127.0.0.1:8081/upload.conf

List files:

    curl -u user:password1 http://127.0.0.1:8081/
