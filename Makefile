.DEFAULT_GOAL := help

db-%:
	$(MAKE) -C mysql $*

_venv:
	virtualenv $@

.PHONY: deps
deps: _venv deps.txt 
	source $</bin/activate; pip install -r $@.txt;

.PHONY: run
run: _venv deps db-test
	source $</bin/activate; gunicorn --reload main:app &
	sleep 1

stop: db-stop
	pkill -f gunicorn || true

.PHONY: test
test: db-_test_data
	curl -F "tsv=@mysql/_test/30b9cdb95aecb5981749/testdata.tsv" \
			localhost:8000/log/memory; \
	curl localhost:8000/users;
	curl localhost:8000/play/top/10/users;
	curl localhost:8000/play/top/10/songs;
	curl localhost:8000/play/top/10/sessions;

.PHONY: help
help:
	@echo "Prequisits: easyinstall pip && pip install virtualenv"
