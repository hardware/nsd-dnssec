NAME = hardware/nsd-dnssec:testing

all: build-no-cache init fixtures run clean
all-fast: build init fixtures run clean
no-build: init fixtures run clean

build-no-cache:
	docker build --no-cache -t $(NAME) .

build:
	docker build -t $(NAME) .

init:
	-docker rm -f nsd_unsigned nsd_default

	sleep 2

	docker run \
		-d \
		--name nsd_unsigned \
		-v "`pwd`/test/config/nsd.conf":/etc/nsd/nsd.conf \
		-v "`pwd`/test/config/db.example.org":/zones/db.example.org \
		-t $(NAME)

	docker run \
		-d \
		--name nsd_default \
		-v "`pwd`/test/config/nsd.conf":/etc/nsd/nsd.conf \
		-v "`pwd`/test/config/db.example.org":/zones/db.example.org \
		-t $(NAME)

fixtures:
	docker exec nsd_default keygen example.org
	docker exec nsd_default signzone example.org

run:
	./test/bats/bin/bats test/tests.bats

clean:
	docker container stop nsd_unsigned nsd_default || true
	docker container rm --volumes nsd_unsigned nsd_default || true
	docker images --quiet --filter=dangling=true | xargs --no-run-if-empty docker rmi
