.DEFAULT_GOAL := help

db-%:
	make -C mysql $*

_venv:
	virtualenv $@

.PHONY: deps
deps: _venv deps.txt 
	source $</bin/activate; pip install -r $@.txt;

.PHONY: start
start: _venv deps db-test
	source $</bin/activate; gunicorn --reload main:app &
	sleep 1

.PHONY: stop
stop: db-stop
	pkill -f gunicorn || true

.PHONY: test
test: db-test_data
	curl -F "tsv=@mysql/_test/30b9cdb95aecb5981749/testdata.tsv" \
			localhost:8000/log/memory; \
	curl localhost:8000/users;
	curl localhost:8000/play/top/10/users;
	curl localhost:8000/play/top/10/songs;
	curl localhost:8000/play/top/10/sessions;

.PHONY: help
help:
	tail -n16 $(lastword $(MAKEFILE_LIST))

# This is the main Makefile of the project.
# It contains rules related to:
# 	Docker - a lightweight OS virtualization platform,
# 	the Python environment and dependencies,
# 	Gunicorn - a fast, RESTful HTTP server.
# It also proxies MySQL related rules, as db-$RULE.
# Example:
# 	make db-start
#
# run:
# 	make $RULE
# , where $RULE can be:
# 	start - start Gunicorn (and MySQL) in the background
# 	stop - stop Gunicorn (and MySQL)
# 	test - test the Gunicorn endpoints
