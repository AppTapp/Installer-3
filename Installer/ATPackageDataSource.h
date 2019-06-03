// AppTapp Installer
// Copyright 2007 Nullriver, Inc.

#import "../Framework/common.h"
#import "UIKit.h"
#import "../Framework/NSDictionary+AppTappSource.h"
#import "../Framework/NSDictionary+AppTappPackage.h"


@class ATInstaller;


@interface ATPackageDataSource : NSObject {
	NSMutableDictionary	*	selectedPackage;
}

// Accessors
- (void)setSelectedPackage:(NSMutableDictionary *)aPackage;
- (NSMutableDictionary *)selectedPackage;
- (UIWebView *)infoWebView;
- (UIScroller *)infoScroller;

@end
