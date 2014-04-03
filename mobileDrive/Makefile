CFLAGS = -g -O2 -Wall -Wextra
LDLIBS = -lsqlite3

vpath %.c dbfs
vpath %.h dbfs

dbfs-demo: dbfs-demo.o dbfs.o
dbfs-demo.o: dbfs-demo.c dbfs.h
dbfs.o: dbfs.c dbfs.h dbfs__literals.h

clean:
	rm -f dbfs-demo *.o

export DBFS=test.db
TESTER=valgrind
test: dbfs-demo
	rm -f "${DBFS}"
	echo 'put foo'
	echo '(contents of foo)' | ${TESTER} ./dbfs-demo put /foo
	echo 'ovr foo'
	echo '(ovr contents of foo)' | ${TESTER} ./dbfs-demo ovr /foo
	echo 'fail bar'
	! echo '(contents of bar)' | ${TESTER} ./dbfs-demo put /sub/bar
	echo 'mkdir sub'
	${TESTER} ./dbfs-demo mkd /sub/
	echo 'put bar'
	echo '(contents of bar)' | ${TESTER} ./dbfs-demo put /sub/bar
	echo 'put baz'
	echo '(contents of baz)' | ${TESTER} ./dbfs-demo put /sub/baz
	echo 'put qux'
	${TESTER} ./dbfs-demo mkd /sub/subsub/
	echo '(contents of qux)' | ${TESTER} ./dbfs-demo put /sub/subsub/qux
	echo 'get foo'
	${TESTER} ./dbfs-demo get /foo
	echo 'get bar'
	${TESTER} ./dbfs-demo get /sub/bar
	echo 'get qux'
	${TESTER} ./dbfs-demo get /sub/subsub/qux
	echo 'list root'
	${TESTER} ./dbfs-demo lsd /
	${TESTER} ./dbfs-demo lsf /
	echo 'list sub'
	${TESTER} ./dbfs-demo lsd /sub/
	${TESTER} ./dbfs-demo lsf /sub/
	echo 'list subsub'
	${TESTER} ./dbfs-demo lsd /sub/subsub/
	${TESTER} ./dbfs-demo lsf /sub/subsub/

	echo 'mvf foo'
	${TESTER} ./dbfs-demo mvf /foo /foo2
	echo 'mvd sub'
	${TESTER} ./dbfs-demo mvd /sub/ /sub2/
	echo 'list root again'
	${TESTER} ./dbfs-demo lsd /
	${TESTER} ./dbfs-demo lsf /

	echo 'rmd subsub'
	${TESTER} ./dbfs-demo rmd /sub2/subsub/
	echo 'list sub again'
	${TESTER} ./dbfs-demo lsd /sub2/
	${TESTER} ./dbfs-demo lsf /sub2/
