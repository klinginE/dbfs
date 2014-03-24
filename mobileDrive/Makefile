CFLAGS = -g -O2 -Wall -Wextra
LDLIBS = -lsqlite3

vpath %.c dbfs
vpath %.h dbfs

dbfs-demo: dbfs-demo.o dbfs.o
dbfs-demo.o: dbfs-demo.c dbfs.h
dbfs.o: dbfs.c dbfs.h dbfs__literals.h

clean:
	rm -f dbfs-demo *.o
