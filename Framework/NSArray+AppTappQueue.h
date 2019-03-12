// AppTapp Framework
// Copyright 2007 Nullriver, Inc.

#import "common.h"
#import "NSDictionary+AppTappPackage.h"


@interface NSArray (AppTappQueue)

- (BOOL)resolveDependencies:(BOOL)automatic;
- (BOOL)containsQueuedPackage:(NSMutableDictionary *)aPackage;

@end
