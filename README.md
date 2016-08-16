# hardware/nsd-dnssec

![nsd](https://i.imgur.com/tPgkQVB.png "nsd")

NSD is an authoritative only, high performance, simple and open source name server.

### Requirement

- Docker 1.0 or higher

### Build-time variables

- **NSD_VERSION** : version of NSD

### Environment variables

- **UID** : nsd user id *(default : 991)*
- **GID** : nsd group id *(default : 991)*

### How to use

```
docker run -d \
  --name nsd \
  -p 53:53 \
  -p 53:53/udp \
  -v /mnt/docker/nsd/conf:/etc/nsd \
  -v /mnt/docker/nsd/zones:/zones \
  -v /mnt/docker/nsd/db:/var/db/nsd \
  hardware/nsd-dnssec
```

#### Setup :

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
@                   IN                NS                   ns6.gandi.net.

; A RECORDS

@                   IN                A                    IPv4
hostname            IN                A                    IPv4
ns1                 IN                A                    IPv4

; CNAME RECORDS

www                 IN                CNAME                hostname

; MAIL RECORDS

@                   IN                MX          10       hostname.domain.tld.

...
```

Check your zone and nsd configuration :

```
docker exec -ti nsd nsd-checkzone domain.tld /zones/db.domain.tld
docker exec -ti nsd nsd-checkconf /etc/nsd/nsd.conf
```

Check the configuration without running the container first:

```
docker run --rm -v `pwd`/zones:/zones -ti hardware/nsd-dnssec nsd-checkzone domain.tld /zones/db.domain.tld
docker run --rm -v `pwd`/conf:/etc/nsd -ti hardware/nsd-dnssec nsd-checkconf /etc/nsd/nsd.conf
```

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

# or set RRSIG RR expiration date :

docker exec -ti nsd signzone domain.tld [YYYYMMDDhhmmss]
docker exec -ti nsd signzone domain.tld 20170205220210
```

**Do not forget to add a cron task to sign your zone periodically to avoid the expiration of RRSIG RR records**

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

### NSD config file sample :

```
# /mnt/docker/nsd/conf/nsd.conf

server:
  server-count: 1
  ip4-only: yes
  hide-version: yes
  identity: ""
  zonesdir: "/zones"

remote-control:
  control-enable: yes

zone:
  name: domain.tld
  zonefile: db.domain.tld.signed
  notify: ip_of_secondary_server NOKEY
  provide-xfr: ip_of_secondary_server NOKEY
  
  # don't answer VERSION.BIND and VERSION.SERVER CHAOS class queries
    hide-version: yes

  # identify the server (CH TXT ID.SERVER entry).
    identity: ""
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
