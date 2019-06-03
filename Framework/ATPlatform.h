// AppTapp Framework
// Copyright 2007 Nullriver, Inc.

#import "common.h"


@interface ATPlatform : NSObject {
}

+ (NSString *)platformName;
+ (NSString *)firmwareVersion;
+ (NSArray *)preNikitaFirmwares;
+ (BOOL)hasNikita;
+ (NSString *)applicationsPath;

@end
