CC=arm-apple-darwin-gcc
CCFLAGS=-nomultidefs -O3 -fvisibility=hidden -I../Framework
LD=$(CC)
LDFLAGS=-ObjC -framework CoreFoundation -framework Foundation -framework UIKit -framework GraphicsServices -framework CoreGraphics -lobjc -lz -force_cpusubtype_ALL -mmacosx-version-min=10.4 -F../Framework -framework AppTapp
SERVICE_LDFLAGS=-ObjC -framework CoreFoundation -framework Foundation -lobjc -lz -force_cpusubtype_ALL -mmacosx-version-min=10.4 -F../Framework -framework AppTapp
STRIP=arm-apple-darwin-strip
INAME=AutoInstaller

SOURCES=		main.o 							\
				AutoInstaller.o

SERVICE_SOURCES=	AutoInstallerService.o 

LIBS=	

all:	Framework AutoInstaller AutoInstallerService

Framework:
		cd ../Framework; make

AutoInstaller:	$(SOURCES)
		mkdir -p $(INAME).app
		$(LD) $(LDFLAGS) -o $(INAME).app/$(INAME) $^ $(LIBS)
		$(STRIP) $(INAME).app/$(INAME)
		cp -Rf resources/* $(INAME).app/
		find -d $(INAME).app -name .svn -exec rm -rf {} \;
		install_name_tool -change AppTapp /Applications/Installer.app/AppTapp.framework/AppTapp $(INAME).app/$(INAME)

AutoInstallerService: $(SERVICE_SOURCES)
		$(LD) $(SERVICE_LDFLAGS) -o $@ $^ $(SERVICE_LIBS)
		$(STRIP) $@
		install_name_tool -change AppTapp /Applications/Installer.app/AppTapp.framework/AppTapp $@

%.o:	%.mm
		$(CC) -c $(CFLAGS) $(CCFLAGS) $< -o $@

clean:
		rm -rf *.o *.app
