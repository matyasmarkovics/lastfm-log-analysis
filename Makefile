.DEFAULT_GOAL := help

mysql-%:
	make -f Makefile.mysql $*

docker-%:
	make -f Makefile.docker $*

_venv:
	virtualenv $@

.PHONY: deps
deps: _venv deps.txt 
	source $</bin/activate; pip install -r $@.txt;

.PHONY: start
start: DB_INSERT_POOL_WORKERS ?= 50
start: DB_INSERT_POOL_CHUNK_SIZE ?= 50
start: _venv deps mysql-test
	source $</bin/activate; \
	DB_INSERT_POOL_WORKERS=$(DB_INSERT_POOL_WORKERS) \
	DB_INSERT_POOL_CHUNK_SIZE=$(DB_INSERT_POOL_CHUNK_SIZE) \
	gunicorn -b 0.0.0.0:8000 --timeout 0 --reload main:app &
	sleep 1

.PHONY: stop
stop: mysql-stop
	pkill -9 -f gunicorn || true

.PHONY: test
test: DATASET_PATH ?= _test/30b9cdb95aecb5981749/testdata.tsv
test: DATASET_IMPORT_MODE ?= memory
test: TOP_N ?= 10
test: mysql-test_data
	curl -X DELETE localhost:8000/log; \
	curl -F "tsv=@$(DATASET_PATH)" \
			localhost:8000/log/$(DATASET_IMPORT_MODE); \
	curl localhost:8000/users;
	curl localhost:8000/play/top/$(TOP_N)/users;
	curl localhost:8000/play/top/$(TOP_N)/songs;
	curl localhost:8000/play/top/$(TOP_N)/sessions;

.PHONY: help
help: docker-help mysql-help
	tail -n16 $(lastword $(MAKEFILE_LIST))

# This is the main Makefile of the project.
# It contains rules related to:
# 	the Python environment, its dependencies and
# 	Gunicorn - a fast, RESTful HTTP server.
# It also proxies Docker and MySQL related rules, as docker-$RULE and mysql-$RULE.
# Examples:
# 	make mysql-start - Will start the MySQL server
# 	make docker-start - Will start the Docker container
#
# run:
# 	make $RULE
# , where $RULE can be:
# 	start - start Gunicorn (and MySQL) in the background
# 	stop - stop Gunicorn (and MySQL)
# 	test - test the Gunicorn endpoints
