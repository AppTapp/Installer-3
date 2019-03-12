// AppTapp Framework
// Copyright 2007 Nullriver, Inc.

#import "NSString+AppTappExtensions.h"


@implementation NSString (AppTappExtensions)

- (NSString *)stringByRemovingPathPrefix:(NSString *)pathPrefix {
	if([pathPrefix isEqualToString:@"."]) return self;

	if([self hasPrefix:pathPrefix]) {
		NSMutableString * result = [NSMutableString stringWithString:self];

		return [result substringFromIndex:[pathPrefix length]];
	} else {
		return self;
	}
}

- (BOOL)isContainedInPath:(NSString *)aPath {
	aPath = [aPath stringByStandardizingPath];

	if([aPath isEqualToString:@"."]) return YES;

	NSArray * components = [self pathComponents];
	NSEnumerator * allComponents = [[aPath pathComponents] objectEnumerator];
	NSString * component;

	unsigned index = 0;
	while(index < [components count] && (component = [allComponents nextObject])) {
		if(![[components objectAtIndex:index] isEqualToString:component]) {
			return NO;
		}
		index++;
	}

	return YES;
}

- (NSString *)stringByExpandingSpecialPathsInPath {
	NSString * result = [self stringByExpandingTildeInPath];

	if([result hasPrefix:@"@Applications"]) {
		result = [[ATPlatform applicationsPath] stringByAppendingPathComponent:[result substringFromIndex:[@"@Applications" length]]];
	}

	return result;
}

@end
