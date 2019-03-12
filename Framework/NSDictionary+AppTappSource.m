// AppTapp Framework
// Copyright 2007 Nullriver, Inc.

#include "NSDictionary+AppTappSource.h"


@implementation NSDictionary (AppTappSource)

- (NSString *)sourceLocation {
	return [self valueForKey:@"location"];
}

- (NSString *)sourceName {
	return [self valueForKey:@"name"];
}

- (NSString *)sourceMaintainer {
	return [self valueForKey:@"maintainer"];
}

- (NSString *)sourceContact {
	return [self valueForKey:@"contact"];
}

- (NSString *)sourceURL {
	return [self valueForKey:@"url"];
}

- (NSString *)sourceCategory {
	NSString * category = [self valueForKey:@"category"];
	return category ? category : __UNCATEGORIZED__;
}

- (NSString *)sourceDescription {
	NSString * description = [self valueForKey:@"description"];
	return description ? description : [self sourceLocation];

	return description;
}

- (NSString *)sourceSponsor {
	return [self valueForKey:@"sponsor"];
}

- (BOOL)isTrustedSource {
	return [[[ATPackageManager sharedPackageManager] trustedSources] containsObject:[[NSURL URLWithString:[self sourceLocation]] comparableStringValue]];
}

- (int)caseInsensitiveCompareSourceCategory:(NSDictionary *)compareValue {
	if([[self sourceCategory] isEqualToString:__DEFAULT_SOURCE_CATEGORY__]) return NSOrderedAscending;
	else if([[compareValue sourceCategory] isEqualToString:__DEFAULT_SOURCE_CATEGORY__]) return NSOrderedDescending;
 
	NSString * a = [NSString stringWithFormat:@"%@.%@", [self sourceCategory], [self sourceName]];
	NSString * b = [NSString stringWithFormat:@"%@.%@", [compareValue sourceCategory], [compareValue sourceName]];

	return [a caseInsensitiveCompare:b];
}

- (BOOL)updateSourceFromInfo:(NSDictionary *)info {
	if(info != nil) {
		[info sourceName] ? [self setValue:[info sourceName] forKey:@"name"] : NO;
		[info sourceMaintainer] ? [self setValue:[info sourceMaintainer] forKey:@"maintainer"] : NO;
		[info sourceContact] ? [self setValue:[info sourceContact] forKey:@"contact"] : NO;
		[info sourceURL] ? [self setValue:[info sourceURL] forKey:@"url"] : NO;
		[info sourceDescription] ? [self setValue:[info sourceDescription] forKey:@"description"] : NO;
		[self setValue:[info sourceSponsor] forKey:@"sponsor"];

		// Source category security checks
		if([info sourceCategory] != nil) {
			if(
				!([[info sourceCategory] hasPrefix:__DEFAULT_SOURCE_CATEGORY__] && ![[self sourceLocation] hasPrefix:__DEFAULT_SOURCE_LOCATION__]) &&
				!([[info sourceCategory] hasPrefix:__COMMUNITY_SOURCES_CATEGORY__] && ![self isTrustedSource])
			) {
				[self setValue:[info sourceCategory] forKey:@"category"];
			}
		}

		return YES;
	} else {
		return NO;
	}
}

@end
