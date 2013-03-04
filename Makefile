all: c64 c64.exe servers kernal

libpp64.so: pp64.c pp64.h
	gcc -Wall -O3 -shared -fPIC -o libpp64.so pp64.c

c64: libpp64.so client.c
	gcc -lpp64 -L. -Wall -O3 -o c64 client.c

c64.exe: client.c pp64.c
	i486-mingw32-g++ -Wall -O3 -static-libgcc -o c64.exe pp64.c client.c

servers: server.prg rrserver.bin

server.prg: server.asm
	kasm -showmem -time -o server.prg server.asm

rrserver.bin: rrserver.asm
	kasm -showmem -time -binfile -o rrserver.bin rrserver.asm

kernal: kernal-901227-03-pp64.bin

kernal-901227-03-pp64.bin: kernal.asm
	kasm -binfile -log kernal.log -o kernal.bin kernal.asm && \
	cp kernal-901227-03.bin kernal-901227-03-pp64.bin && \
	ruby ./tools/patch.rb kernal.bin kernal-901227-03-pp64.bin && \
	rm -v kernal.bin kernal.log

install: libpp64.so c64
	cp pp64.h /usr/include
	cp libpp64.so /usr/lib
	cp c64 /usr/bin

uninstall:
	[ -f /usr/bin/c64 ] && rm -v /usr/bin/c64 || true
	[ -f /usr/lib/libpp64.so ] && rm -v /usr/lib/libpp64.so || true
	[ -f /usr/include/pp64.h ] && rm -v /usr/include/pp64.h || true

clean: 
	[ -f libpp64.so ] && rm -v libpp64.so || true
	[ -f c64 ] && rm -v c64 || true
	[ -f c64.exe ] && rm -v c64.exe || true
	[ -f server.prg ] && rm -v server.prg || true
	[ -f rrserver.bin ] && rm -v rrserver.bin || true
	[ -f kernal-901227-03-pp64.bin ] && rm -v kernal-901227-03-pp64.bin || true

