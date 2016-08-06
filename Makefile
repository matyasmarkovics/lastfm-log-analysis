.DEFAULT_GOAL := help

db-%:
	$(MAKE) -C mysql $*

_venv:
	virtualenv $@

.PHONY: deps
deps: _venv
	source $</bin/activate; pip install -r $@.txt;

.PHONY: run
run: _venv deps db-test
	source $</bin/activate; gunicorn -D main:app
	sleep 1

stop: db-stop
	pkill -f gunicorn

.PHONY: test
test:
	curl localhost:8000/things

.PHONY: help
help:
	@echo "Prequisits: easyinstall pip && pip install virtualenv"
