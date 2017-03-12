# hardware/nsd-dnssec

![nsd](https://i.imgur.com/tPgkQVB.png "nsd")

### What is this ?

NSD is an authoritative only, high performance, simple and open source name server.

### Features

- Lightweight & secure image (no root process)
- Based on Alpine Linux 3.4
- Latest NSD version (4.1.15)
- ZSK and KSK keys, DS-Records management and zone signature with ldns

### Build-time variables

- **NSD_VERSION** : version of NSD
- **GPG_SHORTID** : short gpg key ID
- **GPG_FINGERPRINT** : fingerprint of signing key
- **SHA256_HASH** : SHA256 hash of NSD archive

### Ports

- **53/tcp**
- **53/udp** (for AXFR zones tranfert queries)

### Environment variables

| Variable | Description | Type | Default value |
| -------- | ----------- | ---- | ------------- |
| **UID** | nsd user id | *optional* | 991
| **GID** | nsd group id | *optional* | 991

### Setup :

Put your dns zone file in `/mnt/docker/nsd/zones/db.domain.tld`

Example :

```
$ORIGIN domain.tld.
$TTL 7200

; SOA

@       IN      SOA    ns1.domain.tld. hostmaster.domain.tld. (
                                        2016020202 ; Serial
                                        7200       ; Refresh
                                        1800       ; Retry
                                        1209600    ; Expire
                                        86400 )    ; Minimum

; NAMESERVERS

@                   IN                NS                   ns1.domain.tld.
@                   IN                NS                   ns2.domain.tld.

; A RECORDS

@                   IN                A                    IPv4
hostname            IN                A                    IPv4
ns1                 IN                A                    IPv4
ns2                 IN                A                    IPv4

; CNAME RECORDS

www                 IN                CNAME                hostname

; MAIL RECORDS

@                   IN                MX          10       hostname.domain.tld.

...
```

Put nsd config in `/mnt/docker/nsd/conf/nsd.conf`

Primary server example :

```
server:
  server-count: 1
  ip4-only: yes
  hide-version: yes
  identity: ""
  zonesdir: "/zones"

remote-control:
  control-enable: yes

key:
   name: "sec_key"
   algorithm: hmac-sha256
   secret: "WU9VUl9TRUNSRVRfS0VZCg==" # echo "YOUR_SECRET_KEY" | base64

zone:
  name: domain.tld
  zonefile: db.domain.tld.signed
  notify: ip_of_secondary_server sec_key
  notify: ip_of_secondary_public_server NOKEY
  provide-xfr: ip_of_secondary_server sec_key
  provide-xfr: ip_of_secondary_public_server NOKEY

# "ip_of_secondary_server" is your secondary nameserver IP
# "ip_of_secondary_public_server" can be your registrar's nameserver IP
```

Secondary server example (optional) :

```
server:
  server-count: 1
  ip4-only: yes
  hide-version: yes
  identity: ""
  zonesdir: "/zones"

remote-control:
  control-enable: yes

key:
   name: "sec_key"
   algorithm: hmac-sha256
   secret: "WU9VUl9TRUNSRVRfS0VZCg=="

zone:
    name: domain.tld
    zonefile: db.domain.tld.signed
    allow-notify: ip_of_primary_server sec_key
    request-xfr: AXFR ip_of_primary_server sec_key

# "ip_of_primary_server" is your primary nameserver IP
```

Check your zone and nsd configuration :

```
cd /mnt/docker/nsd
docker run --rm -v `pwd`/zones:/zones -ti hardware/nsd-dnssec nsd-checkzone domain.tld /zones/db.domain.tld
docker run --rm -v `pwd`/conf:/etc/nsd -ti hardware/nsd-dnssec nsd-checkconf /etc/nsd/nsd.conf
```

### Docker-compose

#### Docker-compose.yml

```
nsd:
  image: hardware/nsd-dnssec
  container_name: nsd
  ports:
    - "53:53"
    - "53:53/udp"
  volumes:
    - /mnt/docker/nsd/conf:/etc/nsd
    - /mnt/docker/nsd/zones:/zones
    - /mnt/docker/nsd/db:/var/db/nsd
```

#### Run !

```
docker-compose up -d
```

### Generating DNSSEC keys and signed zone

Generate ZSK and KSK keys with ECDSAP384SHA384 algorithm (it may take some time...) :

```
docker exec -ti nsd keygen domain.tld

Generating ZSK & KSK keys for 'domain.tld'
Done.
```

Then sign your dns zone (default expiration date = 1 month) :

```
docker exec -ti nsd signzone domain.tld

Signing zone for domain.tld
NSD configuration rebuild... reconfig start, read /etc/nsd/nsd.conf
ok
Reloading zone for domain.tld... ok
Notify slave servers... ok
Done.

# or set custom RRSIG RR expiration date :

docker exec -ti nsd signzone domain.tld [YYYYMMDDhhmmss]
docker exec -ti nsd signzone domain.tld 20170205220210
```

:warning: **Do not forget to add a cron task to increment the serial and sign your zone periodically to avoid the expiration of RRSIG RR records !**

Show your DS-Records (Delegation Signer) :

```
docker exec -ti nsd ds-records domain.tld

> DS record 1 [Digest Type = SHA1] :
domain.tld. 600 IN DS xxxx 14 1 xxxxxxxxxxxxxx

> DS record 2 [Digest Type = SHA256] :
domain.tld. 600 IN DS xxxx 14 2 xxxxxxxxxxxxxx

> Public KSK Key :
domain.tld. IN DNSKEY 257 3 14 xxxxxxxxxxxxxx ; {id = xxxx (ksk), size = 384b}

```

Restart the DNS server to take into account the changes :

```
docker-compose restart nsd
```
