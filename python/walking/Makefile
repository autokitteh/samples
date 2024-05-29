all:
	$(error please pick a target)


deploy-workflow:
	ak deploy --manifest ./autokitteh.yaml --file walking.py

run-workflow:
	curl -i -X POST -d@event.json http://localhost:9980/http/walking/

secret:
	ak var set --secret --env walking/default GOOGLE_CREDS < credentials.json
