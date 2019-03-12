// AppTapp Framework
// Copyright 2007 Nullriver, Inc.

#import "NSURL+AppTappExtensions.h"

@implementation NSURL (AppTappExtensions)

- (BOOL)isEqualToURL:(NSURL *)aURL {
	if([[self comparableStringValue] isEqualToString:[aURL comparableStringValue]]) return YES;
	else return NO;
}

- (NSString *)comparableStringValue {
	return [[[self standardizedURL] absoluteString] stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"/"]];
}

@end
