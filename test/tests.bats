load 'test_helper/bats-support/load'
load 'test_helper/bats-assert/load'


@test "check zone" {
  run docker exec nsd_unsigned nsd-checkzone example.org /zones/db.example.org
  assert_success
  assert_output "zone example.org is ok"
}

@test "check conf" {
  run docker exec nsd_unsigned nsd-checkconf /etc/nsd/nsd.conf
  assert_success
  assert_output ""
}

@test "generate key" {
  run docker exec nsd_unsigned [ ! -f /etc/nsd/*.key ]
  assert_success
  run docker exec nsd_unsigned [ ! -f /etc/nsd/*.pem ]
  assert_success
  run docker exec nsd_unsigned keygen example.org
  assert_success
  assert_output "Generating ZSK & KSK keys for 'example.org'"
  run docker exec nsd_unsigned [ -f /etc/nsd/nsd_control.key ]
  assert_success
  run docker exec nsd_unsigned [ -f /etc/nsd/nsd_control.pem ]
  assert_success
  run docker exec nsd_unsigned [ -f /etc/nsd/nsd_server.key ]
  assert_success
  run docker exec nsd_unsigned [ -f /etc/nsd/nsd_server.pem ]
  assert_success
}

@test "check DS records" {
  run docker exec nsd_default ds-records example.org
  assert_success
  assert_line --index 0 '> DS record 1 [Digest Type = SHA1] :'
  assert_line --index 1 --regexp '^example.org.	3600	IN	DS	[0-9]{2,5} 14 1 [0-9a-f]{40}$'
  assert_line --index 2 '> DS record 2 [Digest Type = SHA256] :'
  assert_line --index 3 --regexp '^example.org.	3600	IN	DS	[0-9]{3,5} 14 2 [0-9a-f]{64}$'
  assert_line --index 4 '> Public KSK Key :'
  assert_line --index 5 --regexp '^example.org.	IN	DNSKEY	257 3 14 [^ ]{128} ;\{id = [0-9]{4,5} \(ksk\), size = 384b\}$'
}

@test "dig result" {
  run bash -c "dig example.org @$(docker inspect --format '{{.NetworkSettings.IPAddress}}' nsd_default) | grep -v '^;'"
  assert_success
  assert_line --index 0 'example.org.		3600	IN	A	10.20.30.40'
  assert_line --index 1 'example.org.		3600	IN	NS	ns1.example.org.'
  assert_line --index 2 'example.org.		3600	IN	NS	ns2.example.org.'
  assert_line --index 3 'ns1.example.org.	3600	IN	A	10.20.30.40'
  assert_line --index 4 'ns2.example.org.	3600	IN	A	10.20.30.40'
}

@test "dig rrsig result" {
  run bash -c "dig example.org RRSIG @$(docker inspect --format '{{.NetworkSettings.IPAddress}}' nsd_default) | grep -v '^;'"
  assert_success
  assert_line --index 0 --regexp '^example.org.		3600	IN	RRSIG	SOA 14 2 3600 '
  assert_line --index 1 --regexp '^example.org.		3600	IN	RRSIG	A 14 2 3600 '
  assert_line --index 2 --regexp '^example.org.		3600	IN	RRSIG	NS 14 2 3600 '
  assert_line --index 3 --regexp '^example.org.		3600	IN	RRSIG	MX 14 2 3600 '
  assert_line --index 4 --regexp '^example.org.		3600	IN	RRSIG	DNSKEY 14 2 3600 '
  assert_line --index 5 --regexp '^example.org.		3600	IN	RRSIG	NSEC3PARAM 14 2 3600 '
  assert_line --index 6 --regexp '^example.org.		3600	IN	NS	ns1.example.org.'
  assert_line --index 7 --regexp '^example.org.		3600	IN	NS	ns2.example.org.'
  assert_line --index 8 'ns1.example.org.	3600	IN	A	10.20.30.40'
  assert_line --index 9 'ns2.example.org.	3600	IN	A	10.20.30.40'
}
