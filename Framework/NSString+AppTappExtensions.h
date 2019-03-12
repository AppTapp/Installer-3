// AppTapp Framework
// Copyright 2007 Nullriver, Inc.

#import "common.h"
#import "ATPlatform.h"

@interface NSString (AppTappExtensions)

- (NSString *)stringByRemovingPathPrefix:(NSString *)pathPrefix;
- (BOOL)isContainedInPath:(NSString *)aPath;
- (NSString *)stringByExpandingSpecialPathsInPath;

@end
