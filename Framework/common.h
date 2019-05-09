#import <Foundation/Foundation.h>
#import <CoreFoundation/CoreFoundation.h>

#define preferences					[NSUserDefaults standardUserDefaults]
#define __REFRESH_INTERVAL__				60 * 60 * 12

#define __PRIVATE_PATH__				[@"/Applications/Installer.app/Library" stringByExpandingTildeInPath]
#define __PARENT_TEMP_PATH__			[@"~/Library/Installer" stringByExpandingTildeInPath]
#define __TEMP_PATH__					[__PARENT_TEMP_PATH__ stringByAppendingPathComponent:@"Temp"]

#define __TRUSTED_SOURCES__				[__PRIVATE_PATH__ stringByAppendingPathComponent:@"TrustedSources.plist"]
#define __PACKAGE_SOURCES__				[__PRIVATE_PATH__ stringByAppendingPathComponent:@"PackageSources.plist"]
#define __REMOTE_PACKAGES__				[__PRIVATE_PATH__ stringByAppendingPathComponent:@"RemotePackages.plist"]
#define __LOCAL_PACKAGES__				[__PRIVATE_PATH__ stringByAppendingPathComponent:@"LocalPackages.plist"]

#define __FEATURED_LOCATION__				@"http://pwnstaller.cc/"
#define __TRUSTED_SOURCES_LOCATION__			@"http://repository.apptapp.com/trusted.plist"

#define __DEFAULT_SOURCE_NAME__				@"AppTapp Official"
#define __DEFAULT_SOURCE_CATEGORY__			@"AppTapp"
#define __DEFAULT_SOURCE_LOCATION__			@"http://repository.apptapp.com/"
#define __DEFAULT_SOURCE_MAINTAINER__			@"Nullriver, Inc."
#define __DEFAULT_SOURCE_CONTACT__			@"apptapp@nullriver.com"

#define __INSTALLER_NAME__				@"Installer"
#define __INSTALLER_VERSION__				[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"]
#define __USER_AGENT__					[NSString stringWithFormat:@"AppTapp Installer/%@ (%@/%@, like CFNetwork/100.0)", __INSTALLER_VERSION__, [ATPlatform platformName], [ATPlatform firmwareVersion]]
#define __INSTALLER_BUNDLE_IDENTIFIER__			[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleIdentifier"]
#define __INSTALLER_CATEGORY__				@"System"
#define __INSTALLER_DESCRIPTION__			@"The new AppTapp Installer!"
#define __INSTALLER_SIZE__				@"0"

#define __COMMUNITY_SOURCES_CATEGORY__			@"Community Sources"
#define __UNCATEGORIZED__				@"Uncategorized"

#define __INSTALL_OPERATION__				@"Install"
#define __UPDATE_OPERATION__				@"Update"
#define __UNINSTALL_OPERATION__				@"Uninstall"

#define __SUCCESS__					@"Success"
#define __FAILURE__					@"Failure"

// SKA Local source support
#define __LOCAL_SOURCE_LOCATION__			@"local:"
#define __LOCAL_SOURCE_NAME__				@"Local Packages"
#define __LOCAL_SOURCE_CATEGORY__			@"AppTapp"
#define __LOCAL_SOURCE_MAINTAINER__			@"Nullriver, Inc."
#define __LOCAL_SOURCE_CONTACT__			@"apptapp@nullriver.com"
#define __LOCAL_SOURCE_FOLDER__				[@"~/Media/Installer" stringByExpandingTildeInPath]
#define __LOCAL_SOURCE_DESCRIPTION__		@"Local packages in ~/Media/Installer directory."
