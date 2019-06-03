TESTHOST = iphone.local
HEAVENLY = /usr/local/share/iphone-filesystem
CC = arm-apple-darwin-gcc
CFLAGS = -x objective-c -mmacosx-version-min=10.4 -dynamiclib -O3
LD = arm-apple-darwin-ld
LDFLAGS = -ObjC -syslibroot $(HEAVENLY) \
	  -F$(HEAVENLY)/System/Library/Frameworks \
	  -framework CoreFoundation -framework Foundation \
	  -framework SystemConfiguration -framework IOKit \
	  -framework GraphicsServices \
	  -lSystem -lobjc -lcrypto -lz

BUNDLEFLAGS = -single_module -Y 1455 -dylib -L/usr/local/arm-apple-darwin/lib/ -ldylib1.o

UNZIP=			unzip/unzip.o \
				unzip/crc32.o \
				unzip/crctab.o \
				unzip/crypt.o \
				unzip/envargs.o \
				unzip/explode.o \
				unzip/extract.o \
				unzip/fileio.o \
				unzip/globals.o \
				unzip/inflate.o \
				unzip/list.o \
				unzip/match.o \
				unzip/process.o \
				unzip/ttyio.o \
				unzip/unreduce.o \
				unzip/unshrink.o \
				unzip/zipinfo.o \
				unzip/unix.o \
				unzip/api.o


all:			bundle


clean:	
			rm -rf *.o AppTapp AppTapp.framework


%.o:			%.m
			$(CC) -c $(CFLAGS) $< -o $@

%.o:	%.c
		$(CC) -c $(CFLAGS) $(CCFLAGS) -DUNIX -DDLL -DUSE_ZLIB -DBSD $< -o $@


AppTapp:		ATPackageManager.o ATDownloader.o ATUnpacker.o ATScript.o NSString+AppTappExtensions.o NSDate+AppTappExtensions.o NSFileManager+AppTappExtensions.o NSNumber+AppTappExtensions.o NSURLRequest+AppTappExtensions.o NSURL+AppTappExtensions.o NSArray+AppTappSources.o NSArray+AppTappPackages.o NSArray+AppTappQueue.o NSDictionary+AppTappQueue.o NSDictionary+AppTappSource.o NSDictionary+AppTappPackage.o ATPlatform.o ATSourceFetcher.o unzip.o ioapi.o 
			$(LD) $(LDFLAGS) $(BUNDLEFLAGS) $^ -o $@


bundle:			AppTapp
			rm -rf AppTapp.framework
			mkdir -p AppTapp.framework
			cp AppTapp AppTapp.framework/AppTapp
			cp Info.plist AppTapp.framework/Info.plist


test:			all
			scp -r AppTapp.framework root@$(TESTHOST):/Applications/Installer.app/

