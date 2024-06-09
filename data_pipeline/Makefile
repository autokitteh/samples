all:
	$(error please pick a target)

start-db:
	docker run -d \
		--name pipeline_pg \
		-e POSTGRES_HOST_AUTH_METHOD=trust \
		-p 5432:5432 \
		postgres:16-alpine

create-table:
	docker exec -it pipeline_pg psql -U postgres < schema.sql
