// AppTapp Installer
// Copyright 2007 Nullriver, Inc.

#import "../Framework/ATPackageManager.h"
#import "../Framework/NSArray+AppTappSources.h"
#import "UIKit.h"
#import "ATDetailCell.h"


@interface ATController : NSObject {
	ATPackageManager	*	packageManager;

	UIView			*	view;
	UITransitionView	*	contentView;
	UINavigationBar		*	navBar;
}

// Factory
- (id)initInView:(UITransitionView *)aView withTitle:(NSString *)aTitle;

// Accessors
- (UIView *)view;
- (UINavigationBar *)navBar;
- (CGRect)viewFrame;
- (CGRect)contentFrame;

// Methods
- (void)controllerDidBecomeKey;
- (void)controllerDidLoseKey;
- (void)popNavigationBarItems;
- (void)packageManagerFinishedQueueWithResult:(NSString *)aResult;

@end
