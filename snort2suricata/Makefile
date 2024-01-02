all: build run
build:
	docker build --tag=snort2suricata .
clean:
	docker rmi snort2suricata || true
	rm -f rule.txt out
run:
	./run.sh
