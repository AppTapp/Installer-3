TESTHOST = replace-with-your-device-ip
HEAVENLY = /usr/local/share/iphone-filesystem
CC = arm-apple-darwin-gcc
CFLAGS = -Wall -x objective-c -mmacosx-version-min=10.4
LD = arm-apple-darwin-ld
LDFLAGS = -ObjC -syslibroot $(HEAVENLY) \
	  -F$(HEAVENLY)/System/Library/Frameworks \
	  -framework CoreFoundation -framework Foundation \
	  -framework UIKit -framework LayerKit -framework CoreGraphics \
	  -framework WebCore -framework GraphicsServices \
	  -framework CoreSurface -framework AppSupport \
	  -L/usr/local/arm-apple-darwin/lib/ -lSystem -lobjc \
	  -F../Framework -framework AppTapp

APPFLAGS=-lcrt1.o


all:			bundle


clean:	
			rm -rf *.o Installer Installer.app installer-3.12.zip ../Framework/AppTapp ../Framework/AppTapp.framework ../Framework/*.o


%.o:			%.m
			$(CC) -c $(CFLAGS) $< -o $@


Framework:
			cd ../Framework; make


Installer:		main.o ATInstaller.o ATPackageDataSource.o ATDetailCell.o ATController.o ATFeaturedController.o ATInstallController.o ATUpdateController.o ATUninstallController.o ATSourcesController.o
			$(LD) $(LDFLAGS) $(APPFLAGS) -o $@ $^
			install_name_tool -change AppTapp /Applications/Installer.app/AppTapp.framework/AppTapp $@


bundle:			Framework Installer
			rm -rf Installer.app
			mkdir -p Installer.app
			cp -rf ../Framework/AppTapp.framework Installer.app/AppTapp.framework
			cp Installer Installer.app/Installer
			cp Info.plist Installer.app/Info.plist
			cp Default.png Installer.app/Default.png
			cp icon.png Installer.app/icon.png
			cp Featured.png Installer.app/Featured.png
			cp FeaturedSelected.png Installer.app/FeaturedSelected.png
			cp Install.png Installer.app/Install.png
			cp InstallSelected.png Installer.app/InstallSelected.png
			cp Update.png Installer.app/Update.png
			cp UpdateSelected.png Installer.app/UpdateSelected.png
			cp Uninstall.png Installer.app/Uninstall.png
			cp UninstallSelected.png Installer.app/UninstallSelected.png
			cp Sources.png Installer.app/Sources.png
			cp SourcesSelected.png Installer.app/SourcesSelected.png
			cp Source.png Installer.app/Source.png
			cp SourceTrusted.png Installer.app/SourceTrusted.png
			cp SourceLocal.png Installer.app/SourceLocal.png
			cp Category.png Installer.app/Category.png
			cp CategorySmart.png Installer.app/CategorySmart.png
			cp Package.png Installer.app/Package.png
			cp PackageNew.png Installer.app/PackageNew.png
			cp Background.png Installer.app/Background.png
			cp -Rf resources/* Installer.app/
			cp -r ../Library Installer.app/Library

zip:			bundle
			rm -rf installer.zip
			zip -r installer-3.13.zip Installer.app 

test:			all
			ssh root@$(TESTHOST) rm -rf /Applications/Installer.app
			scp -r Installer.app root@$(TESTHOST):/Applications/
			ssh root@$(TESTHOST) chown -R root:wheel /Applications/Installer.app
			ssh root@$(TESTHOST) chmod 4755 /Applications/Installer.app/Installer
			ssh root@$(TESTHOST) killall -9 SpringBoard


