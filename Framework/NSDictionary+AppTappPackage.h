// AppTapp Framework
// Copyright 2007 Nullriver, Inc.

#import "common.h"

@class ATPackageManager;

@interface NSDictionary (AppTappPackage)

- (NSMutableArray *)packageSource;
- (NSString *)packageSourceLocation;
- (NSString *)packageName;
- (NSString *)packageVersion;
- (NSString *)packageBundleIdentifier;
- (NSString *)packageHash;
- (NSString *)packageLocation;
- (NSString *)packageSize;
- (NSString *)packageAuthor;
- (NSString *)packageMaintainer;
- (NSString *)packageContact;
- (NSString *)packageURL;
- (NSString *)packageDescription;
- (NSString *)packageCategory;
- (NSDate *)packageDate;
- (NSString *)packageSponsor;
- (BOOL)isValidPackage;
- (BOOL)isTrustedPackage;
- (BOOL)isInstallablePackage;
- (BOOL)isUpdateablePackage;
- (BOOL)isUninstallablePackage;
- (BOOL)isNewPackage;
- (NSString *)packageTempFile;
- (NSArray *)packageScriptNamed:(NSString *)scriptName;

- (int)caseInsensitiveComparePackageName:(NSDictionary *)compareValue;
- (int)caseInsensitiveComparePackageCategory:(NSDictionary *)compareValue;
- (int)comparePackageDate:(NSDictionary *)compareValue;

@end
