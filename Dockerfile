FROM alpine:3.3
MAINTAINER Hardware <contact@meshup.net>

RUN apk -U add \
    nsd \
    ldns \
    ldns-tools \
    openssl \
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
