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
start: _venv deps mysql-test
	source $</bin/activate; gunicorn -b 0.0.0.0:8000 --reload main:app &
	sleep 1

.PHONY: stop
stop: mysql-stop
	pkill -f gunicorn || true

.PHONY: test
test: mysql-test_data
	curl -F "tsv=@_test/30b9cdb95aecb5981749/testdata.tsv" \
			localhost:8000/log/memory; \
	curl localhost:8000/users;
	curl localhost:8000/play/top/10/users;
	curl localhost:8000/play/top/10/songs;
	curl localhost:8000/play/top/10/sessions;

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
