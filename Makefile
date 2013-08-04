
check: test

test:

packages:
	apt-get install build-essential git python-software-properties curl -y

master:
	echo $1

.PHONY: test