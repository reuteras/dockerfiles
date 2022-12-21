# nginx with upload

## Configure

Start with changing _server_name_ in _upload.conf_ from localhost to the name you like to use.

## Build

Build the container:

    docker build --tag reuteras/nginx .

## Run

Run the container and store files in the _./upload_ directory:

    docker run --rm --name nginx -p 80:80 -v $(pwd)/upload:/usr/share/nginx/html/upload reuteras/nginx

## Usage

To use it with Microsoft [avml](https://github.com/microsoft/avml), observe that the file is written to disk first.

    avml --url http://localhost/upload/$(hostname)-output.lime output.lime

With curl you can use the following command to PUT the file:
    
    curl --upload-file upload.conf http://localhost/upload/upload.conf
