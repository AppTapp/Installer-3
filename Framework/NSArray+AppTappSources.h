// AppTapp Framework
// Copyright 2007 Nullriver, Inc.

#import "common.h"
#import "NSURL+AppTappExtensions.h"
#import "NSDictionary+AppTappSource.h"


@interface NSArray (AppTappSources)

- (BOOL)containsSourceWithLocation:(NSString *)location;
- (NSMutableDictionary *)sourceWithLocation:(NSString *)location;
- (int)indexOfSourceCategory:(NSString *)aCategory;
- (NSArray *)sourceCategories;

@end
