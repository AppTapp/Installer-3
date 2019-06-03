// AppTapp Framework
// Copyright 2007 Nullriver, Inc.

#import "ATPlatform.h"
#import <GraphicsServices/GraphicsServices.h>

//extern CFTypeRef GSSystemGetCapability(CFStringRef identity);
static CFTypeRef (*$GSSystemCopyCapability)(CFStringRef);

@implementation ATPlatform

+ (NSString *)platformName {
	/* SKA 03/14/08 Added real platform detection (iPhone or iPod) using GS's capabilities */
	//id caps = (id)GSSystemGetCapability(NULL);
	
	//if (caps && [caps isKindOfClass:[NSDictionary class]])
	//{
	//	return ([caps objectForKey:@"deviceName"] ? [caps objectForKey:@"deviceName"] : @"iPhone");
	//}
	/* ~SKA */
	
	return @"iPhone";
}

+ (NSString *)firmwareVersion {
	return [[NSDictionary dictionaryWithContentsOfFile:@"/System/Library/CoreServices/SystemVersion.plist"] valueForKey:@"ProductVersion"];
}

+ (NSArray *)preNikitaFirmwares {
	return [NSArray arrayWithObjects:
			@"1.0",
			@"1.0.1",
			@"1.0.2",
			@"1.1",
			@"1.1.1",
			@"1.1.2",
		nil];
}

+ (BOOL)hasNikita {
	return ![[self preNikitaFirmwares] containsObject:[self firmwareVersion]];
}

+ (NSString *)applicationsPath {
	return @"/Applications";
}

@end
