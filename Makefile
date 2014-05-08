TESTS = app/ app/**/specs/*_spec.coffee app/**/specs/**/*_spec.coffee

test:
	@NODE_ENV=test ./node_modules/.bin/mocha \
	    --compilers coffee:coffee-script/register --growl --reporter list \
			$(TESTS)
.PHONY: test

