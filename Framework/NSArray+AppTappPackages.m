// AppTapp Framework
// Copyright 2007 Nullriver, Inc.

#import "NSArray+AppTappPackages.h"


@implementation NSArray (AppTappPackages)

- (BOOL)containsPackage:(NSMutableDictionary *)aPackage {
	if([self packageWithBundleIdentifier:[aPackage packageBundleIdentifier]] != nil) return YES;
	else return NO;
}

- (NSMutableDictionary *)packageWithBundleIdentifier:(NSString *)anIdentifier {
        NSEnumerator * allPackages = [self objectEnumerator];
        NSMutableDictionary * package;

	while((package = [allPackages nextObject])) {
		if([[package packageBundleIdentifier] isEqualToString:anIdentifier]) return package;
	}

	return nil;
}

- (int)indexOfPackageCategory:(NSString *)aCategory {
	NSEnumerator * allPackages = [self objectEnumerator];
	NSMutableDictionary * package;
	int count = 0;

	while((package = [allPackages nextObject])) {
		if([[package packageCategory] isEqualToString:aCategory]) return count;
		count++;
	}

	return NSNotFound;
}

- (NSArray *)packageCategories {
	NSMutableArray * categories = [NSMutableArray array];

	NSEnumerator * allPackages = [self objectEnumerator];
	NSMutableDictionary * package;

	while((package = [allPackages nextObject])) {
		NSString * category = [package packageCategory];

		if(![categories containsObject:category]) [categories addObject:category];
	}

	return categories;
}

- (BOOL)allPackagesAreTrusted {
	NSEnumerator * allPackages = [self objectEnumerator];
	NSMutableDictionary * package;

	while((package = [allPackages nextObject])) {
		if(![package isTrustedPackage]) return NO;
	}

	return YES;
}

@end
