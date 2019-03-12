// AppTapp Framework
// Copyright 2007 Nullriver, Inc.

#import "NSArray+AppTappSources.h"


@implementation NSArray (AppTappSources)

- (BOOL)containsSourceWithLocation:(NSString *)location {
	if([self sourceWithLocation:location] != nil) return YES;
	else return NO;
}

- (NSMutableDictionary *)sourceWithLocation:(NSString *)location {
	NSEnumerator * allSources = [self objectEnumerator];
	NSMutableDictionary * source;

	while((source = [allSources nextObject])) {
		if([[NSURL URLWithString:[source sourceLocation]] isEqualToURL:[NSURL URLWithString:location]]) return source;
	}

	return nil;
}

- (int)indexOfSourceCategory:(NSString *)aCategory {
	NSEnumerator * allSources = [self objectEnumerator];
	NSMutableDictionary * source;
	int count = 0;

	while((source = [allSources nextObject])) {
		if([[source sourceCategory] isEqualToString:aCategory]) return count;
		count++;
	}

	return 0;
}

- (NSArray *)sourceCategories {
	NSMutableArray * categories = [NSMutableArray array];

	NSEnumerator * allSources = [self objectEnumerator];
	NSMutableDictionary * source;

	while((source = [allSources nextObject])) {
		NSString * category = [source sourceCategory];

		if(![categories containsObject:category]) [categories addObject:category];
	}

	return categories;
}

@end
