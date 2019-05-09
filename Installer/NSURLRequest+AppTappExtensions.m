// AppTapp Framework
// Copyright 2007 Nullriver, Inc.

#import "NSURLRequest+AppTappExtensions.h"
#import "ATPlatform.h"

@implementation NSURLRequest (AppTappExtensions)

+ (id)requestWithURL:(NSURL *)aURL {
	NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:aURL cachePolicy:/*NSURLRequestReloadIgnoringCacheData*/NSURLRequestUseProtocolCachePolicy timeoutInterval:30.0];
	[request setValue:__USER_AGENT__ forHTTPHeaderField:@"User-Agent"];

	return request;
}

@end
