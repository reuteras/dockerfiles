# Elastic labs

Some notes and documentation from testing the ELK stack. The final goal is to find a good solution for logging on Linux. First I tried the [RSS example][lrf] from the Elastic blog. Then I started with auditbeat and the auditd framework. After that I started to look at Sysmon for Linux just to see an example of a source of Linux information based on eBPF.

## RSS

This is my notes and a setup scrips to test [How to leverage RSS feeds to inform the possibilities with Elastic Stack][lrf] in a fast and easy way. It's also good to look at the [GitHub][git] repository corresponding to that blog post.

To setup the environment from scratch run.

    ./setup-rss.sh

Lastly you probably will like to disable sending data to Elastic. Open [http://localhost:5601/app/management/kibana/settings](http://localhost:5601/app/management/kibana/settings) and search for "Provide usage data".

The ELK stack is running as separate containers with the help of [docker-elk][del].


## Auditbeat and auditd

Test auditbeat with Elastic to see how it handles audit logs. Inspiration from [Monitoring Linux Audit Logs with auditd and Auditbeat][mla]. The [Auditbeat Reference][are] and [auditbeat.reference.yml][ary] example file is useful to read through.

First fix file permissions for the file auditbeat.yml file (change default and add rules if necessary):

    sudo chown root:root auditbeat/auditbeat.yml
    sudo chmod go-w auditbeat/auditbeat.yml

Then run setup to configure Elastic and Kibana.

    docker run --name=auditbeat --rm --user=root --volume="$(pwd)/auditbeat/auditbeat.yml:/usr/share/auditbeat/auditbeat.yml:ro" --cap-add="AUDIT_CONTROL" --cap-add="AUDIT_READ" --pid=host --network docker-elk_elk docker.elastic.co/beats/auditbeat:8.4.3 auditbeat setup -e

Run auditbeat (you must run **sudo systemctl stop auditd** before):

    docker run -d --name=auditbeat --user=root --volume="$(pwd)/auditbeat/auditbeat.yml:/usr/share/auditbeat/auditbeat.yml:ro" --cap-add="AUDIT_CONTROL" --cap-add="AUDIT_READ" --pid=host --network docker-elk_elk docker.elastic.co/beats/auditbeat:8.4.3 -e --strict.perms=false

Check logs with the following command:

    docker logs -f auditbeat


## Sysmon for Linux

More information about [SysmonForLinux][sfl] and [SysinternalsEBPF][seb] can be found here:

- Automating the deployment of Sysmon for Linux 🐧 and Azure Sentinel in a lab environment 🧪
- [Sysmon for Linux config][slc] - by MSTIC
- [SysmonForLinux-CollectAll-config.xml][scc]

I tested this on a VM with Ubuntu 20.04 LTS. To get started first run the set setup script for SysmonForLinux:

    ./setup-sysmonforlinux.sh

Logs are sent to syslog by default and can be viewed as usual with **tail** and other standard Linux tools:

    tail -f /var/log/syslog 

There is also a tool included in the package that can format the output and select the specific events (1 = ProcessCreate, 3 = NetworkConnect Detected):

    sudo tail -f /var/log/syslog | sudo /opt/sysmon/sysmonLogView -e 1
    sudo tail -f /var/log/syslog | sudo /opt/sysmon/sysmonLogView -e 3

There isn't any real need for sudo for **sysmonLogView** but Microsoft installs the files with only *root* allowed to access files under */opt/sysmon*...

### TODO

- [ ] Get logs to elastic?

## Filebeat and auditd

First make sure that **auditd** is installed (started automatically).

    sudo apt install -y auditd

Test with Filebeat running in docker. From the page [Run Filebeat on Docker][rfd]

    docker pull docker.elastic.co/beats/filebeat:8.4.3

Run setup for Filebeat. It might be possible to run this in one command.

    docker run --rm \
        --network docker-elk_elk \
        docker.elastic.co/beats/filebeat:8.4.3 \
        setup -E setup.kibana.host=kibana:5601 \
              -E output.elasticsearch.hosts=["elasticsearch:9200"]

    docker run --rm \
        --network docker-elk_elk \
        docker.elastic.co/beats/filebeat:8.4.3 \
        setup --dashboards -E setup.kibana.host=kibana:5601 \
              -E output.elasticsearch.hosts=["elasticsearch:9200"]

Fix permissions for files in the *filebeat* directory.

    chmod 600 filebeat/*.yml
    chown root:root filebeat/*.yml

Run Filebeat:

    docker run -d \
        --name=filebeat \
        --user=root \
        --network docker-elk_elk \
        --volume="$(pwd)/filebeat.yml:/usr/share/filebeat/filebeat.yml:ro" \
        --volume="$(pwd)/auditd.yml:/usr/share/filebeat/modules.d/auditd.yml:ro" \
        --volume="$(pwd)/kibana.yml:/usr/share/filebeat/modules.d/kibana.yml:ro" \
        --volume="/var/log/audit:/audit:ro" \
        docker.elastic.co/beats/filebeat:8.4.3 filebeat -e --strict.perms=false

Documentation for Filebeat and its auditd module:

- [Filebeat Reference][fir]
- [Auditd module][aum]
- [Kibana module][kim]
- [Importing Existing Beat Dashboards][ieb]

### MISP - Elastic Stack - Docker

Add script to make it easier to test [MISP - Elastic Stack - Docker][med]



  [are]: https://www.elastic.co/guide/en/beats/auditbeat/current/index.html
  [ary]: https://www.elastic.co/guide/en/beats/auditbeat/current/auditbeat-reference-yml.html
  [aum]: https://www.elastic.co/guide/en/beats/filebeat/current/filebeat-module-auditd.html
  [del]: https://github.com/deviantony/docker-elk
  [fir]: https://www.elastic.co/guide/en/beats/filebeat/current/index.html
  [git]: https://github.com/cyberimposters/rss-security
  [ieb]: https://www.elastic.co/guide/en/beats/devguide/8.4/import-dashboards.html
  [kim]: https://www.elastic.co/guide/en/beats/filebeat/current/filebeat-module-kibana.html
  [med]: https://www.misp-project.org/2024/04/05/elastic-misp-docker.html/
  [mla]: https://sematext.com/blog/auditd-logs-auditbeat-elasticsearch-logsene/
  [lrf]: https://www.elastic.co/blog/how-to-leverage-rss-feeds-to-inform-the-possibilities-with-elastic-stack
  [rfd]: https://www.elastic.co/guide/en/beats/filebeat/current/running-on-docker.html
  [scc]: https://gist.github.com/Cyb3rWard0g/bcf1514cc340197f0076bf1da8954077
  [seb]: https://github.com/Sysinternals/SysinternalsEBPF
  [sfl]: https://github.com/Sysinternals/SysmonForLinux
  [slc]: https://github.com/microsoft/MSTIC-Sysmon/tree/main/linux/configs

