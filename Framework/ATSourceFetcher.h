// AppTapp Framework
// Copyright 2007 Nullriver, Inc.

#import "common.h"
#import "NSFileManager+AppTappExtensions.h"
#import "NSDictionary+AppTappPackage.h"

@class ATPackageManager;

@interface ATSourceFetcher : NSObject {
	NSDictionary		*	source;
	NSURLConnection		*	connection;
	NSFileHandle		*	downloadFile;
	NSString			*	fileName;
	id						delegate;
}

+ (id)refreshSource:(NSDictionary *)aSource notifying:(id)aDelegate;
- (id)initWithSource:(NSDictionary *)aSource withDelegate:(id)aDelegate;

- (void)start;
@end
