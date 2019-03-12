// AppTapp Framework
// Copyright 2007 Nullriver, Inc.

#import "common.h"
#import <openssl/md5.h>


@interface NSFileManager (AppTappExtensions)

- (NSString *)fileHashAtPath:(NSString *)aPath;
- (BOOL)createPath:(NSString *)aPath handler:(id)handler;
- (BOOL)copyPath:(NSString *)source toPath:(NSString *)destination handler:(id)handler;
- (NSNumber *)freeSpaceAtPath:(NSString *)aPath;

@end
