# snort2surcicata

This container uses Google [gonids](https://github.com/google/gonids) to convert a [Snort](https://www.snort.org/) rule in *rule.txt* in the current directory to a [Suricata](https://suricata-ids.org/) rule.

Build the container:

    docker build --tag=snort2suricata .

Run the container:

    docker run -it --rm -v "$(pwd)"/rule.txt:/go/src/app/rule.txt --name snort2suricata snort2suricata
