MYSQLD := $(shell which mysqld_safe &> /dev/null && echo mysqld_safe || echo mysqld)
MYSQL_CMD_PATH := $(shell which mysql)
MYSQL_BASEDIR := $(dir $(realpath $(MYSQL_CMD_PATH)))../
MYSQL_SOCKET := ./_data/mysql.sock

stop:
	pkill mysqld || true 

clean: stop
	rm -rf _data

init: clean
	mysql_install_db \
		--basedir=$(MYSQL_BASEDIR) \
		--datadir=./_data

start: init
	$(MYSQLD) \
		--socket=$(notdir $(MYSQL_SOCKET)) \
		--timezone=UTC \
		--basedir=$(MYSQL_BASEDIR) \
		--datadir=./_data &
	sleep 1

create: start
	mysql --socket=$(MYSQL_SOCKET) -u root < lastfm_schema.sql

console:
	mysql --socket=$(MYSQL_SOCKET) -u root

_test:
	mkdir _test

_test/30b9cdb95aecb5981749/testdata.tsv: _test
	cd _test; git clone git@gist.github.com:30b9cdb95aecb5981749.git

_test_data: _test/30b9cdb95aecb5981749/testdata.tsv

MYTAP := _test/mytap/mytap.sql
$(MYTAP): _test
	cd _test; git clone git@github.com:matyasmarkovics/mytap.git

mytap: $(MYTAP)
	cd $(dir $<); mysql --socket=../../$(MYSQL_SOCKET) -u root < $@.sql

test: create retest

retest: _test_data mytap
	mysql --socket=$(MYSQL_SOCKET) -u root < lastfm_schema.tap.sql
