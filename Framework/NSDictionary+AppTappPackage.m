// AppTapp Framework
// Copyright 2007 Nullriver, Inc.

#import "NSDictionary+AppTappPackage.h"


@implementation NSDictionary (AppTappPackage)

- (NSMutableArray *)packageSource {
	return [[[ATPackageManager sharedPackageManager] packageSources] sourceWithLocation:[self packageSourceLocation]];
}

- (NSString *)packageSourceLocation {
	return [self valueForKey:@"source"];
}
- (NSString *)packageName {
	return [self valueForKey:@"name"];
}

- (NSString *)packageVersion {
	return [self valueForKey:@"version"];
}

- (NSString *)packageBundleIdentifier {
	return [self valueForKey:@"bundleIdentifier"];
}

- (NSString *)packageHash {
	return [self valueForKey:@"hash"];
}

- (NSString *)packageLocation {
	return [self valueForKey:@"location"];
}

- (NSString *)packageSize {
	return [self valueForKey:@"size"];
}

- (NSString *)packageAuthor {
	return [self valueForKey:@"author"];
}

- (NSString *)packageMaintainer {
	return [self valueForKey:@"maintainer"];
}

- (NSString *)packageContact {
	return [self valueForKey:@"contact"];
}

- (NSString *)packageURL {
	return [self valueForKey:@"url"];
}

- (NSString *)packageDescription {
	return [self valueForKey:@"description"];
}

- (NSString *)packageCategory {
	NSString * category = [self valueForKey:@"category"];

	if(category == nil) return @"Uncategorized";
	else return category;
}

- (NSDate *)packageDate {
	return [NSDate dateWithTimeIntervalSince1970:[[self valueForKey:@"date"] doubleValue]];
}

- (NSString *)packageSponsor {
	return [self valueForKey:@"sponsor"];
}

- (BOOL)isValidPackage {
	if(
		[self packageName] != nil &&
		[self packageVersion] != nil &&
		[self packageLocation] != nil &&
		[self packageSize] != nil &&
		[self packageBundleIdentifier] != nil
	) return YES;
	else return NO;
}

- (BOOL)isTrustedPackage {
	return [[self packageSource] isTrustedSource];
}

- (BOOL)isInstallablePackage {
	return ([[self packageScriptNamed:@"install"] count] > 0);
}

- (BOOL)isUpdateablePackage {
	return ([[self packageScriptNamed:@"install"] count] > 0 || [[self packageScriptNamed:@"update"] count] > 0 );
}

- (BOOL)isUninstallablePackage {
	return ([[self packageScriptNamed:@"uninstall"] count] > 0);
}

- (BOOL)isNewPackage {
	return [[self packageDate] timeIntervalSince1970] > [[NSDate dateWithTimeIntervalSinceNow:-60*60*72] timeIntervalSince1970];
}

- (NSString *)packageTempFile {
	return [__TEMP_PATH__ stringByAppendingPathComponent:[[self packageLocation] lastPathComponent]];
}

- (NSArray *)packageScriptNamed:(NSString *)scriptName {
	return [[self objectForKey:@"scripts"] objectForKey:scriptName];
}

- (int)caseInsensitiveComparePackageName:(NSDictionary *)compareValue {
	return [[self packageName] caseInsensitiveCompare:[compareValue packageName]];
}

- (int)caseInsensitiveComparePackageCategory:(NSDictionary *)compareValue {
	NSString * a = [NSString stringWithFormat:@"%@.%@", [self packageCategory], [self packageName]];
	NSString * b = [NSString stringWithFormat:@"%@.%@", [compareValue packageCategory], [compareValue packageName]];

	return [a caseInsensitiveCompare:b];
}

- (int)comparePackageDate:(NSDictionary *)compareValue {
	return [[compareValue packageDate] compare:[self packageDate]];
}

@end
