// AppTapp Framework
// Copyright 2007 Nullriver, Inc.

#import "NSDictionary+AppTappQueue.h"


@implementation NSDictionary (AppTappQueue)

- (NSMutableDictionary *)queuedPackage {
	return [self valueForKey:@"package"];
}

- (NSString *)queuedOperation {
	return [self valueForKey:@"operation"];
}

@end
