// AppTapp Framework
// Copyright 2007 Nullriver, Inc.

#import "common.h"
#import "NSFileManager+AppTappExtensions.h"
#import "NSDictionary+AppTappPackage.h"

@class ATPackageManager;

@interface ATDownloader : NSObject {
	NSMutableDictionary	*	package;
	NSURLConnection		*	connection;
	NSFileHandle		*	downloadFile;
	unsigned			downloadSize;
	unsigned			downloadBytes;
	id				delegate;
}

+ (BOOL)downloadPackage:(NSMutableDictionary *)aPackage notifying:(id)aDelegate;
- (BOOL)initWithPackage:(NSMutableDictionary *)aPackage withDelegate:(id)aDelegate;

// Methods
- (BOOL)checkPackageTempFile;

@end
