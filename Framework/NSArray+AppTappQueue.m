// AppTapp Framework
// Copyright 2007 Nullriver, Inc.

#import "NSArray+AppTappQueue.h"


@implementation NSArray (AppTappQueue)

- (BOOL)resolveDependencies:(BOOL)automatic {
	return YES;
}

- (BOOL)containsQueuedPackage:(NSMutableDictionary *)aPackage {
        NSEnumerator * allQueuedOperations = [self objectEnumerator];
        NSDictionary * queuedPackage;
                
        while(queuedPackage = [[allQueuedOperations nextObject] queuedPackage]) {
                if([[queuedPackage packageBundleIdentifier] isEqualToString:[aPackage packageBundleIdentifier]]) return YES;
        }
        
        return NO;
}

@end
