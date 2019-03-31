// AppTapp Installer
// Copyright 2007 Nullriver, Inc.

#import "../Framework/common.h"
#import "../Framework/ATPackageManager.h"
#import "UIKit.h"
#import "ATFeaturedController.h"
#import "ATInstallController.h"
#import "ATUpdateController.h"
#import "ATUninstallController.h"
#import "ATSourcesController.h"


@interface ATInstaller : UIApplication {
	BOOL				needsSuspend;
	BOOL				needsRestart;
	ATPackageManager	*	packageManager;
	BOOL				canContinue;
	BOOL				shouldShowProgressSheet;
	BOOL				shouldTerminate;
	unsigned			confirmedButton;

	UIWindow		*	window;
	UIView			*	mainView;
	UITransitionView	*	contentView;
	UIButtonBar		*	buttonBar;

	UIProgressBar		*	progressBar;
	UIAlertSheet		*	progressSheet;
	BOOL				progressSheetVisible;

	ATFeaturedController	*	featuredController;
	ATInstallController	*	installController;
	ATUpdateController	*	updateController;
	ATUninstallController	*	uninstallController;
	ATSourcesController	*	sourcesController;

	ATController		*	keyController;
}

+ (ATInstaller *)sharedInstaller;
- (NSArray *)buttonBarItems;

// Accessors
- (UIView *)mainView;

// Methods
- (void)askToDonate;
- (void)showProgressSheet;
- (void)hideProgressSheet;
- (void)refresh;
- (void)refreshOneSource:(NSDictionary*)source;
- (void)updateBadges;
- (void)switchToPackageWithIdentifier:(NSString *)identifier;

- (BOOL)checkPermissions;
@end
