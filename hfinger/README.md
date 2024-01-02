docker build --tag=hfinger .
docker run -it --rm -v /Users/reuteras/tmp/pcap:/hfinger/pcap --name hfinger hfinger /bin/bash
