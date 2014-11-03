PERLDIR="/usr/local/share/perl5/"
TARGET="TimUtil.pm"

install:
	mkdir -p ${PERLDIR}; \
	cp ${TARGET} ${PERLDIR}
