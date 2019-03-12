// AppTapp Framework
// Copyright 2007 Nullriver, Inc.

#import "common.h"
#import "ATPackageManager.h"


@interface NSDictionary (AppTappSource)

- (NSString *)sourceLocation;
- (NSString *)sourceName;
- (NSString *)sourceMaintainer;
- (NSString *)sourceContact;
- (NSString *)sourceURL;
- (NSString *)sourceCategory;
- (NSString *)sourceDescription;
- (NSString *)sourceSponsor;
- (BOOL)isTrustedSource;
- (int)caseInsensitiveCompareSourceCategory:(NSDictionary *)compareValue;
- (BOOL)updateSourceFromInfo:(NSDictionary *)info;

@end
