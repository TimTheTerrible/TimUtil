PERLDIR=/usr/local/lib64/perl5
TARGET=TimUtil.pm
BUILDDIR="build"

install:
	mkdir -p ${PERLDIR}; \
	cp ${TARGET} ${PERLDIR}

test:
	perl -I . ./test.pl --debug=all --help

diff:
	diff ${TARGET} ${PERLDIR}/${TARGET}

clean:
	rm -vrf ${BUILDDIR}

package:
	rpmbuild -ba TimUtil.spec

