#!/bin/sh -e
make
export DBFS=test.db
rm -f "$DBFS"
echo 'put foo'
echo '(contents of foo)' | ./dbfs-demo put /foo
echo 'ovr foo'
echo '(ovr contents of foo)' | ./dbfs-demo ovr /foo
echo 'put bar'
echo '(contents of bar)' | ./dbfs-demo put /sub/bar
echo 'put baz'
echo '(contents of baz)' | ./dbfs-demo put /sub/baz
echo 'put qux'
echo '(contents of qux)' | ./dbfs-demo put /sub/subdir2/qux
echo 'get foo'
./dbfs-demo get /foo
echo 'get bar'
./dbfs-demo get /sub/bar
echo 'get qux'
./dbfs-demo get /sub/subdir2/qux
echo 'list root'
./dbfs-demo lsd /
./dbfs-demo lsf /
echo 'list sub'
./dbfs-demo lsd /sub/
./dbfs-demo lsf /sub/
echo 'list sub2'
./dbfs-demo lsd /sub/subdir2/
./dbfs-demo lsf /sub/subdir2/
