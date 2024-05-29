all:
	$(error please pick a target)


deploy-workflow:
	ak deploy --manifest ./autokitteh.yaml --file handler.py

run-workflow:
	curl -i -X POST -d@event.json http://localhost:9980/http/walking/
