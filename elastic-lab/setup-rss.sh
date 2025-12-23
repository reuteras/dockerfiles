#!/bin/bash

sudo apt update > /dev/null

echo "Install packages. Update pip and install/update docker-compose."
sudo apt install -y curl docker.io git python3-pip > /dev/null
python3 -m pip install -U pip > /dev/null
python3 -m pip install -U docker-compose > /dev/null

sudo sysctl -w vm.max_map_count=262144

if ! grep "docker" /etc/group | grep -E "(:|,)${USER}" > /dev/null ; then
    sudo adduser "${USER}" docker
    echo "Logout to update group memberships."
    exit
fi

[[ ! -d ~/docker-elk ]] && git clone https://github.com/deviantony/docker-elk.git ~/docker-elk
[[ ! -d ~/rss-security ]] && git clone https://github.com/cyberimposters/rss-security.git ~/rss-security

sed -i -e 's/changeme/password/' ~/docker-elk/.env
sed -i -e 's/ELASTIC_VERSION=.*/ELASTIC_VERSION=8.13.1/' ~/docker-elk/.env
sed -i -e 's/trial/basic/' ~/docker-elk/elasticsearch/config/elasticsearch.yml
sed -i -e 's/xpack.security.enabled: true/xpack.security.enabled: false/' ~/docker-elk/elasticsearch/config/elasticsearch.yml

if ! grep rss ~/docker-elk/logstash/Dockerfile > /dev/null ; then
    echo "RUN /usr/share/logstash/bin/logstash-plugin install logstash-input-rss" >> \
        ~/docker-elk/logstash/Dockerfile
    CURRENT="$(pwd)"
    cd ~/docker-elk || exit
    docker-compose build
    cd "${CURRENT}" || exit
fi

if grep LOGSTASH ~/docker-elk/logstash/pipeline/logstash.conf > /dev/null ; then
    sed -i -e 's/password => .*/password => "password"/' ~/docker-elk/logstash/pipeline/logstash.conf
fi

echo "Open a terminal and run 'docker-compose up' in ~/docker-elk/."
echo ""
read -rp "Press enter when done." dummy
echo ""
echo "Open http://localhost:5601/app/dev_tools#/console and insert:"
echo ""
cat ~/rss-security/templates/rss-component_template.json
echo ""
echo ""
read -rp "Press enter when done." dummy
echo ""
cat ~/rss-security/templates/rss-index_template.json
echo ""
echo ""
read -rp "Press enter when done." dummy
echo ""
echo "Open http://localhost:5601/app/management/kibana/objects and click import."
echo "Open the folder ~/rss-security/kibana/saved_objects/."
echo "Drag the detailed file and import it."
echo ""
read -rp "Press enter when done." dummy
echo "${dummy}" > /dev/null
echo ""
if ! grep rss ~/docker-elk/logstash/pipeline/logstash.conf > /dev/null ; then
    cat ~/rss-security/logstash/rss-security-feed.conf >> ~/docker-elk/logstash/pipeline/logstash.conf
    sed -i -e 's/localhost/elasticsearch/' ~/docker-elk/logstash/pipeline/logstash.conf
fi
echo "Restart docker with docker-compose restart."
