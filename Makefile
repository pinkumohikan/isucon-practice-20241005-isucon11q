.PHONY: *

gogo: stop-services truncate-logs start-services bench

stop-services:
	sudo systemctl stop nginx
	sudo systemctl stop isucondition.php
	ssh isucon-s3 "sudo systemctl stop mysql"

truncate-logs:
	sudo journalctl --vacuum-size=1K
	sudo truncate --size 0 /var/log/nginx/access.log
	sudo truncate --size 0 /var/log/nginx/error.log
	sudo truncate --size 0 /var/log/mysql/slow.log
	sudo truncate --size 0 /var/log/mysql/error.log

start-services:
	ssh isucon-s3 "sudo systemctl start mysql"
	sudo systemctl start isucondition.php
	sudo systemctl start nginx

kataribe: timestamp=$(shell TZ=Asia/Tokyo date "+%Y%m%d-%H%M%S")
kataribe:
	mkdir -p ~/kataribe-logs
	sudo cp /var/log/nginx/access.log /tmp/last-access.log && sudo chmod 0666 /tmp/last-access.log
	cat /tmp/last-access.log | kataribe -conf kataribe.toml > ~/kataribe-logs/$$timestamp.log
	cat ~/kataribe-logs/$$timestamp.log | grep --after-context 20 "Top 20 Sort By Total"

pprof: TIME=60
pprof: PROF_FILE=~/pprof.samples.$(shell TZ=Asia/Tokyo date +"%H%M").$(shell git rev-parse HEAD | cut -c 1-8).pb.gz
pprof:
	curl -sSf "http://localhost:6060/debug/fgprof?seconds=$(TIME)" > $(PROF_FILE) go tool pprof $(PROF_FILE)

bench:
	ssh isucon-bench "cd bench && ./bench -all-addresses 172.31.46.68 -target 172.31.46.68:443 -tls -jia-service-url http://172.31.41.25:4999"

