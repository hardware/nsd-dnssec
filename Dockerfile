FROM alpine:3.4
MAINTAINER Hardware <contact@meshup.net>

ARG NSD_VERSION=4.1.12
ARG SHA256_NSD="fd1979dff1fba55310fd4f439dc9f3f4701d435c0ec4fb9af533e12c7f27d5de"
ARG GPG_NSD="EDFA A3F2 CA4E 6EB0 5681  AF8E 9F6F 1C2D 7E04 5F8D"

ENV UID=991 GID=991

RUN echo "@community https://nl.alpinelinux.org/alpine/v3.4/community" >> /etc/apk/repositories \
 && BUILD_DEPS=" \
    gnupg \
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
    tini@community \
 && cd /tmp \
 && wget -q https://www.nlnetlabs.nl/downloads/nsd/nsd-${NSD_VERSION}.tar.gz \
 && wget -q https://www.nlnetlabs.nl/downloads/nsd/nsd-${NSD_VERSION}.tar.gz.asc \
 && echo "Verifying both integrity and authenticity of nsd-${NSD_VERSION}.tar.gz..." \
 && CHECKSUM=$(sha256sum nsd-${NSD_VERSION}.tar.gz | awk '{print $1}') \
 && if [ "${CHECKSUM}" != "${SHA256_NSD}" ]; then echo "Warning! Checksum does not match!" && exit 1; fi \
 && gpg --recv-keys 7E045F8D \
 && FINGERPRINT="$(LANG=C gpg --verify nsd-${NSD_VERSION}.tar.gz.asc nsd-${NSD_VERSION}.tar.gz 2>&1 \
  | sed -n "s#Primary key fingerprint: \(.*\)#\1#p")" \
 && if [ -z "${FINGERPRINT}" ]; then echo "Warning! Invalid GPG signature!" && exit 1; fi \
 && if [ "${FINGERPRINT}" != "${GPG_NSD}" ]; then echo "Warning! Wrong GPG fingerprint!" && exit 1; fi \
 && echo "All seems good, now unpacking nsd-${NSD_VERSION}.tar.gz..." \
 && tar xzf nsd-${NSD_VERSION}.tar.gz && cd nsd-${NSD_VERSION} \
 && ./configure \
    CFLAGS="-O2 -flto -fPIE -U_FORTIFY_SOURCE -D_FORTIFY_SOURCE=2 -fstack-protector-strong -Wformat -Werror=format-security" \
    LDFLAGS="-Wl,-z,now -Wl,-z,relro" \
 && make && make install \
 && apk del ${BUILD_DEPS} \
 && rm -rf /var/cache/apk/* /tmp/* /root/.gnupg

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
CMD ["startup"]
