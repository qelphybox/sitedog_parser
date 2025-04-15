.PHONY: test

test:
	bundle exec rake test

install:
	bundle install

build:
	bundle exec rake build

release:
	bundle exec rake release

console:
	bundle exec bin/console