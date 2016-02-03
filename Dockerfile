FROM alpine:3.3
MAINTAINER Hardware <contact@meshup.net>

RUN apk -U add \
    nsd \
    ldns \
    ldns-tools \
    openssl \
  && rm -f /var/cache/apk/*

RUN nsd-control-setup

COPY keygen /usr/sbin/keygen
COPY signzone /usr/sbin/signzone

RUN chmod +x /usr/sbin/keygen /usr/sbin/signzone

VOLUME /zones /etc/nsd
EXPOSE 53/udp
CMD ["nsd", "-d"]