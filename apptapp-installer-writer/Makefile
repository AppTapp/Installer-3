CC=gcc
LD=$(CC)

LDFLAGS=-L/usr/lib -lxml2  -lcurl
LDFLAGS_DAEMON=-Wl,-syslibroot,/usr/local/share/iphone-filesystem -lobjc -ObjC -lxml2 -lz

CFLAGS =-I/usr/include/libxml2


pxlm: 
	$(CC) $(CFLAGS) aiw.c $(LDFLAGS) -o aiw

