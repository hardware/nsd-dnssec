FROM alpine:3.3
MAINTAINER Hardware <contact@meshup.net>

RUN echo "@testing http://nl.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories

RUN apk -U add \
    nsd \
    ldns \
    ldns-tools \
    libressl@testing \
  && rm -f /var/cache/apk/*

COPY keygen /usr/sbin/keygen
COPY signzone /usr/sbin/signzone
COPY ds-records /usr/sbin/ds-records
COPY startup /usr/sbin/startup

RUN chmod +x /usr/sbin/keygen \
             /usr/sbin/signzone \
             /usr/sbin/ds-records \
             /usr/sbin/startup

VOLUME /zones /etc/nsd
EXPOSE 53 53/udp
CMD ["startup"]
