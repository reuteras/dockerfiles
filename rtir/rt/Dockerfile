FROM debian:bookworm-slim
LABEL maintainer="Coding <code@ongoing.today>"

ENV DEBIAN_FRONTEND=noninteractive
# Perl settings -n to don't to tests
ENV RT_FIX_DEPS_CMD=/usr/bin/cpanm
ENV PERL_CPANM_OPT=-n
ENV USER=rt-service
ENV UID=1000
ENV GID=1000
ENV RT_VERSION=5.0.7
ENV RTIR_VERSION=5.0.6

SHELL ["/bin/bash", "-eo", "pipefail", "-c"]
RUN apt update -yqq && \
    apt install -yqq --no-install-recommends \
        autoconf \
        build-essential \
        ca-certificates \
        cpanminus \
        cron \
        curl \
        dnsutils \
        git \
        gpgv2 \
        gnupg \
        graphviz \
        libexpat-dev \
        libio-socket-ssl-perl \
        libpq-dev \
        libgd-dev \
        libssl-dev \
        libz-dev \
        lighttpd \
        lighttpd-mod-openssl \
        mailutils \
        msmtp \
        multiwatch \
        openssl \
        perl \
        postgresql-client \
        ssl-cert \
        supervisor \
        traceroute \
        w3m && \
# Create user and group
    addgroup \
        --gid "$GID" \
        "$USER" && \
    adduser \
        --disabled-password \
        --gecos "" \
        --home "$(pwd)" \
        --ingroup "$USER" \
        --no-create-home \
        --uid "$UID" \
        "$USER" && \
    mkdir -p /var/log/supervisor && \
    mkdir -p /opt/rt5 && \
    chmod 0750 /opt/rt5 && \
    chown rt-service:rt-service /opt/rt5 && \
    mkdir -p /tmp/rt && \
    curl -SL "https://download.bestpractical.com/pub/rt/release/rt-${RT_VERSION}.tar.gz" | \
        tar -xzC /tmp/rt && \
    cd /tmp/rt/rt* && \
    (echo y; echo o conf prerequisites_policy follow; echo o conf commit) | perl -MCPAN -e shell && \
    ./configure \
        --enable-graphviz \
        --enable-gd \
        --enable-gpg \
        --with-web-handler=fastcgi \
        --with-bin-owner=rt-service \
        --with-libs-owner=rt-service \
        --with-libs-group=rt-service \
        --with-db-type=Pg \
        --with-web-user=rt-service \
        --with-web-group=rt-service \
        --prefix=/opt/rt5 \
        --with-rt-group=rt-service && \
    make fixdeps && \
    make testdeps && \
    make config-install dirs files-install fixperms instruct && \
    cpanm RT::Extension::TerminalTheme && \
    cpanm Net::Domain::TLD && \
    cpanm Parse::BooleanLogic && \
    mkdir -p /tmp/rtir && \
    curl -SL "https://download.bestpractical.com/pub/rt/release/RT-IR-${RTIR_VERSION}.tar.gz" | \
        tar -xzC /tmp/rtir && \
    cd /tmp/rtir/* && \
    perl Makefile.PL && \
    make install && \
# Clean up
    apt remove -y \
        build-essential && \
    apt-get clean && \
    apt-get autoclean && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /root/.cpan && \
    rm -rf /root/.cpanm && \
    rm -rf /preseed.txt /usr/share/doc && \
    rm -rf /tmp/rt && \
    rm -rf /usr/local/share/man /var/cache/debconf/*-old

# Copy files to docker
COPY 89-rt.conf /etc/lighttpd/conf-available/89-rt.conf
COPY pg_backup.sh /etc/periodic/daily/pg_backup
COPY entrypoint.sh /entrypoint.sh
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

RUN chmod +x /entrypoint.sh && \
    /usr/sbin/lighty-enable-mod accesslog && \
    /usr/sbin/lighty-enable-mod rt && \
    chmod 770 /opt/rt5/etc && \
    rm -f /opt/rt5/etc/RT_SiteConfig.pm && \
    ln -s /data/RT_SiteConfig.pm /opt/rt5/etc/RT_SiteConfig.pm && \
    chmod 0770 /opt/rt5/var && \
    chmod 0644 /etc/lighttpd/conf-available/89-rt.conf && \
    chown rt-service:rt-service /etc/lighttpd/conf-available/89-rt.conf && \
    touch /var/run/lighttpd.pid && \
    chown rt-service:rt-service /var/run/lighttpd.pid && \
    chown -R rt-service:rt-service /var/log/lighttpd /var/cache/lighttpd && \
    chown -R rt-service:rt-service /opt/rt5 && \
    echo "host $RT_RELAYHOST" > /etc/msmtprc && \
    echo "from $RT_SENDER" >> /etc/msmtprc && \
    echo "domain $RT_DOMAIN" >> /etc/msmtprc && \
    chown rt-service:rt-service /etc/msmtprc && \
    ln -s /usr/bin/msmtp /usr/sbin/sendmail

ENTRYPOINT ["/entrypoint.sh"]

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
