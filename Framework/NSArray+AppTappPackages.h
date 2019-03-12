// AppTapp Framework
// Copyright 2007 Nullriver, Inc.

#import "common.h"
#import "NSDictionary+AppTappPackage.h"


@interface NSArray (AppTappPackages)

- (BOOL)containsPackage:(NSMutableDictionary *)aPackage;
- (NSMutableDictionary *)packageWithBundleIdentifier:(NSString *)anIdentifier;
- (int)indexOfPackageCategory:(NSString *)aCategory;
- (NSArray *)packageCategories;
- (BOOL)allPackagesAreTrusted;

@end
