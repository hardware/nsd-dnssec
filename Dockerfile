FROM alpine:3.3
MAINTAINER Hardware <contact@meshup.net>

ARG NSD_VERSION=4.1.9

ENV UID=991 GID=991

RUN echo "@commuedge http://nl.alpinelinux.org/alpine/edge/community" >> /etc/apk/repositories \
 && BUILD_DEPS=" \
    build-base \
    libevent-dev \
    openssl-dev \
    ca-certificates" \
 && apk -U add \
    ${BUILD_DEPS} \
    ldns \
    ldns-tools \
    libevent \
    openssl \
    tini@commuedge \
 && cd /tmp && wget -q https://www.nlnetlabs.nl/downloads/nsd/nsd-${NSD_VERSION}.tar.gz \
 && tar xzf nsd-${NSD_VERSION}.tar.gz && cd nsd-${NSD_VERSION} \
 && ./configure && make && make install \
 && apk del ${BUILD_DEPS} \
 && rm -rf /var/cache/apk/* /tmp/*

COPY keygen /usr/sbin/keygen
COPY signzone /usr/sbin/signzone
COPY ds-records /usr/sbin/ds-records
COPY startup /usr/sbin/startup

RUN chmod +x /usr/sbin/keygen \
             /usr/sbin/signzone \
             /usr/sbin/ds-records \
             /usr/sbin/startup

VOLUME /zones /etc/nsd /var/db/nsd
EXPOSE 53 53/udp
CMD ["/sbin/tini","--","startup"]
