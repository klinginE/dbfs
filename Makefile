CFLAGS = -g -O2 -Wall -Wextra
LDLIBS = -lsqlite3

dbfs-demo: dbfs-demo.o dbfs.o
dbfs-demo.o: dbfs-demo.c dbfs.h
dbfs.o: dbfs.c dbfs.h

clean:
	rm -f dbfs-demo *.o
