GCC=gcc
FLAGS=-DUSB_VID=$(USB_VID) -DUSB_PID=$(USB_PID) -std=gnu99 -Wall -O3 -I.

#GCC-MINGW32=i486-mingw32-gcc
GCC-MINGW32=i686-pc-mingw32-gcc

#KASM=java -jar /usr/share/kickassembler/KickAss.jar
KASM=java -jar c:/cygwin/usr/share/kickassembler/KickAss.jar

RELEASE=1.0

LIBHEADERS=\
	xlink.h \
	util.h \
	extension.h \
	driver/driver.h \
	driver/protocol.h \
	driver/usb.h \
	driver/parport.h

LIBSOURCES=\
	xlink.c \
	util.c \
	extension.c \
	extensions.c \
	driver/driver.c \
	driver/usb.c \
	driver/parport.c

#all: linux c64
all: win32 c64
c64: server kernal bootstrap
linux: xlink
win32: xlink.exe
server: xlink-server.prg
kernal: commodore/kernal-901227-03.rom xlink-kernal.rom
bootstrap: bootstrap.txt

libxlink.so: $(LIBHEADERS) $(LIBSOURCES)
	$(GCC) $(FLAGS) -shared -fPIC \
		-Wl,-init,libxlink_initialize,-fini,libxlink_finalize\
		-o libxlink.so $(LIBSOURCES) -lusb

xlink: libxlink.so client.c client.h disk.c disk.h
	$(GCC) $(FLAGS) -o xlink client.c disk.c -L. -lxlink -lreadline

xlink.dll: $(LIBHEADERS) $(LIBSOURCES)
	$(GCC-MINGW32) $(FLAGS) -shared -o xlink.dll $(LIBSOURCES) -lusb

xlink.exe: xlink.dll client.c client.h disk.c disk.h 
	$(GCC-MINGW32) $(FLAGS) -o xlink.exe client.c disk.c -L. -lxlink

extensions.c: tools/make-extension extensions.asm
	$(KASM) -binfile -o extensions.bin extensions.asm | \
	grep make-extension | \
	sh > extensions.c && rm extensions.bin

tools/make-extension: tools/make-extension.c
	$(GCC) $(FLAGS) -o tools/make-extension tools/make-extension.c

tools/make-bootstrap: tools/make-bootstrap.c
	$(GCC) $(FLAGS) -o tools/make-bootstrap tools/make-bootstrap.c

bootstrap.txt: tools/make-bootstrap bootstrap.asm
	$(KASM) -o bootstrap.prg bootstrap.asm | grep 'make-bootstrap' | \
	sh -x > bootstrap.txt && \
	rm -v bootstrap.prg

xlink-server.prg: server.h server.asm 
	$(KASM) -o xlink-server.prg server.asm

xlink-kernal.rom: server.h kernal.asm
	cp commodore/kernal-901227-03.rom xlink-kernal.rom && \
	$(KASM) -binfile kernal.asm | grep dd | sh -x >& /dev/null && rm -v kernal.bin

firmware: driver/at90usb162/xlink.c driver/at90usb162/xlink.h
	(cd driver/at90usb162 && make)

firmware-clean:
	(cd driver/at90usb162 && make clean)

firmware-install: xlink firmware
	LD_LIBRARY_PATH=. ./xlink bootloader && \
	sleep 5 && \
	(cd driver/at90usb162 && make dfu)

install: xlink c64
	install -m755 xlink /usr/bin
	install -m644 libxlink.so /usr/lib
	install -m644 xlink.h /usr/include
	install -m644 -D xlink-server.prg /usr/share/xlink/xlink-server.prg
	install -m644 -D xlink-kernal.rom /usr/share/xlink/xlink-kernal.rom
	install -m644 -D bootstrap.txt /usr/share/xlink/xlink-bootstrap.txt
	[ -d /etc/bash_completion.d ] &&  \
		install -m644 etc/bash_completion.d/xlink /etc/bash_completion.d/

uninstall:
	rm -v /usr/bin/xlink
	rm -v /usr/lib/libxlink.so
	rm -v /usr/include/xlink.h
	rm -rv /usr/share/xlink
	[ -f /etc/bash_completion.d/xlink ] && rm -v /etc/bash_completion.d/xlink

clean: firmware-clean
	[ -f libxlink.so ] && rm -v libxlink.so || true
	[ -f xlink.dll ] && rm -v xlink.dll || true
	[ -f xlink ] && rm -v xlink || true
	[ -f xlink.exe ] && rm -v xlink.exe || true
	[ -f extensions.c ] && rm -v extensions.c || true
	[ -f xlink-server.prg ] && rm -v xlink-server.prg || true
	[ -f xlink-kernal.rom ] && rm -v xlink-kernal.rom || true
	[ -f bootstrap.txt ] && rm -v bootstrap.txt || true
	[ -f tools/make-extension ] && rm -v tools/make-extension || true
	[ -f tools/make-bootstrap ] && rm -v tools/make-bootstrap || true
	[ -f log ] && rm -v log || true

release: clean
	git archive --prefix=xlink-$(RELEASE)/ -o ../xlink-$(RELEASE).tar.gz HEAD
