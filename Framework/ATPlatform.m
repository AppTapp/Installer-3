// AppTapp Framework
// Copyright 2007 Nullriver, Inc.

#import "ATPlatform.h"

extern CFTypeRef GSSystemGetCapability(CFStringRef identity);
extern int ripdev_uuid(char * uuid);

@implementation ATPlatform

+ (NSString *)platformName {
	/* SKA 03/14/08 Added real platform detection (iPhone or iPod) using GS's capabilities */
	id caps = (id)GSSystemGetCapability(NULL);
	
	if (caps && [caps isKindOfClass:[NSDictionary class]])
	{
		return ([caps objectForKey:@"deviceName"] ? [caps objectForKey:@"deviceName"] : @"iPhone");
	}
	/* ~SKA */
	
	return @"iPhone";
}

+ (NSString *)deviceUUID
{
	char deviceUUID[64];
	
	if (ripdev_uuid(deviceUUID) == 0)
	{
		return [NSString stringWithCString:deviceUUID];
	}
	
	return nil;
}

+ (NSString *)firmwareVersion {
	return [[NSDictionary dictionaryWithContentsOfFile:@"/System/Library/CoreServices/SystemVersion.plist"] valueForKey:@"ProductVersion"];
}

+ (NSArray *)preNikitaFirmwares {
	return [NSArray arrayWithObjects:
			@"1.0",
			@"1.0.1",
			@"1.0.2",
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
