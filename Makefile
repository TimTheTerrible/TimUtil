PERLDIR="/usr/local/lib64/perl5/"
TARGET="TimUtil.pm"

install:
	mkdir -p ${PERLDIR}; \
	cp ${TARGET} ${PERLDIR}

test:
	perl -I . ./test.pl --debug=all --help
