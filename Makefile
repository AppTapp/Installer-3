TESTHOST = mjuPhone.local.
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
			rm -rf *.o Installer Installer.app


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
			find -d Installer.app -name .svn -exec rm -rf {} \;
			chmod +s Installer.app/Installer
			sudo chown root:wheel Installer.app/Installer

zip:			bundle
			rm -rf Installer.zip
			zip -9yr Installer.zip Installer.app


test:			all
			scp -r Installer.app root@$(TESTHOST):/Applications/

