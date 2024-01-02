#!/bin/bash

docker run -it --rm -v "$(pwd)"/rule.txt:/go/src/app/rule.txt --name snort2suricata snort2suricata
