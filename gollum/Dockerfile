FROM ruby:3.3-alpine3.21

LABEL maintainer="Coding <code@ongoing.today>"

RUN apk update && \
    apk add --no-cache cmake=3.31.3-r0 \
        git=2.47.1-r0 \
        icu-dev=76.1-r0 && \
    gem install --no-document github-linguist:7.28.0 && \
    gem install --no-document gollum:5.3.1 && \
    gem install --no-document org-ruby:0.9.12 && \
    apk del cmake git icu-dev && \
    rm -rf /var/cache/apk/*

WORKDIR /wiki

USER nobody

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:8080/ || exit 1

ENTRYPOINT ["gollum", "--port", "8080", "--lenient-tag-lookup", "."]
EXPOSE 8080
