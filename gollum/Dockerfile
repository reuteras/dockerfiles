FROM ruby:3
LABEL maintainer="Coding <code@ongoing.today>"
RUN apt-get -y update && \
    apt-get -y dist-upgrade && \
    apt-get -y install --no-install-recommends cmake \
        git \
        libicu-dev && \
    gem install github-linguist && \
    gem install gollum && \
    gem install org-ruby && \
    apt-get -y remove cmake git && \
    apt-get -y autoremove && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /wiki
ENTRYPOINT ["gollum", "--port", "8080", "--lenient-tag-lookup", "."]
EXPOSE 8080
