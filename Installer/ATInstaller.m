	// AppTapp Installer
// Copyright 2007 Nullriver, Inc.

#include "ATInstaller.h"


@implementation ATInstaller

static ATInstaller * sharedInstance = nil;

#pragma mark -
#pragma mark Factory

+ (ATInstaller *)sharedInstaller {
	if(sharedInstance == nil) sharedInstance = [[self alloc] init];

	return sharedInstance;
}

- (id)init {
	if((self = [super init])) {
		sharedInstance = self;
		NSLog(@"ATInstaller: Initializing...");
		needsSuspend = NO;
		needsRestart = NO;
		packageManager = [[ATPackageManager sharedPackageManager] retain];
		[packageManager setDelegate:self];

		canContinue = YES;
		shouldShowProgressSheet = YES;
		shouldTerminate = NO;
	}

	return self;
}

- (void)dealloc {
	[packageManager release];
	[window release];
	[mainView release];
	[contentView release];
	[progressBar release];
	[progressSheet release];
	[featuredController release];
	[installController release];
	[updateController release];
	[uninstallController release];
	[sourcesController release];
	[buttonBar release];

	[super dealloc];
}

- (void)applicationDidFinishLaunching:(id)unused {
	window = [[UIWindow alloc] initWithContentRect:[UIHardware fullScreenApplicationContentRect]];
	mainView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 320.0f, 460.0f)];
	contentView = [[UITransitionView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 320.0f, 411.0f)];

	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
	float white[] = { 1.0f, 1.0f, 1.0f, 1.0f };
	[contentView setBackgroundColor:CGColorCreate(colorSpace, white)];
	CGColorSpaceRelease(colorSpace);

	progressBar = [[UIProgressBar alloc] initWithFrame:CGRectMake(320.0f / 2 - 100.0f, 34.0f, 200.0f, 20.0f)];
	progressSheet = [[UIAlertSheet alloc] init];
	[progressSheet setTitle:NSLocalizedString(@"Please wait...", @"Installer Main")];
	[progressSheet setBodyText:@" "];
	[progressSheet setDelegate:self];
	[progressSheet setAlertSheetStyle:2];
	[progressSheet addSubview:progressBar];
	progressSheetVisible = NO;

	featuredController = [[ATFeaturedController alloc] initInView:contentView withTitle:NSLocalizedString(@"Featured", @"Installer Main")];
	installController = [[ATInstallController alloc] initInView:contentView withTitle:NSLocalizedString(@"Categories", @"Installer Main")];
	updateController = [[ATUpdateController alloc] initInView:contentView withTitle:NSLocalizedString(@"Updates", @"Installer Main")];
	uninstallController = [[ATUninstallController alloc] initInView:contentView withTitle:NSLocalizedString(@"Packages", @"Installer Main")];
	sourcesController = [[ATSourcesController alloc] initInView:contentView withTitle:NSLocalizedString(@"Sources", @"Installer Main")];

	buttonBar = [[UIButtonBar alloc] initInView:mainView withFrame:CGRectMake(0.0f, 411.0f, 320.0f, 49.0f) withItemList:[self buttonBarItems]];
	[buttonBar setDelegate:self];
	[buttonBar setBarStyle:1];
	[buttonBar setButtonBarTrackingMode:2];

	int buttons[5] = { 1, 2, 3, 4, 5};
	[buttonBar registerButtonGroup:0 withButtons:buttons withCount:5];
	[buttonBar showButtonGroup:0 withDuration:0.0f];
	
	int tag;
	for(tag = 1; tag < 6; tag++) {
		[[buttonBar viewWithTag:tag] setFrame:CGRectMake(2.0f + ((tag - 1) * 63.0f), 1.0f, 64.0f, 48.0f)];
	}

	// Snapshot
	keyController = featuredController;
	[featuredController controllerDidBecomeKey];

	[contentView transition:0 toView:[featuredController view]];
	[buttonBar showSelectionForButton:1];

	// Finish up
	[mainView addSubview:contentView];
	[window setContentView:mainView];
	[window orderFront:self];
	[window makeKey:self];

	[packageManager performUpgrade];

	// Refresh if needed
	if([packageManager refreshIsNeeded]) [self performSelector:@selector(refresh) withObject:nil afterDelay:0.5f];
	else [self updateBadges];

	if ([self checkPermissions])
		[self askToDonate];
}

- (NSArray *)buttonBarItems {
	return [NSArray arrayWithObjects:
			[NSDictionary dictionaryWithObjectsAndKeys:
				@"buttonBarItemTapped:", kUIButtonBarButtonAction,
				@"Featured.png", kUIButtonBarButtonInfo,
				@"FeaturedSelected.png", kUIButtonBarButtonSelectedInfo,
				[NSNumber numberWithInt:1], kUIButtonBarButtonTag,
				self, kUIButtonBarButtonTarget,
				NSLocalizedString(@"Featured", @"Installer Main"), kUIButtonBarButtonTitle,
				@"0", kUIButtonBarButtonType,
			nil],
			[NSDictionary dictionaryWithObjectsAndKeys:
				@"buttonBarItemTapped:", kUIButtonBarButtonAction,
				@"Install.png", kUIButtonBarButtonInfo,
				@"InstallSelected.png", kUIButtonBarButtonSelectedInfo,
				[NSNumber numberWithInt:2], kUIButtonBarButtonTag,
				self, kUIButtonBarButtonTarget,
				NSLocalizedString(@"Install", @"Installer Main"), kUIButtonBarButtonTitle,
				@"0", kUIButtonBarButtonType,
			nil],
			[NSDictionary dictionaryWithObjectsAndKeys:
				@"buttonBarItemTapped:", kUIButtonBarButtonAction,
				@"Update.png", kUIButtonBarButtonInfo,
				@"UpdateSelected.png", kUIButtonBarButtonSelectedInfo,
				[NSNumber numberWithInt:3], kUIButtonBarButtonTag,
				self, kUIButtonBarButtonTarget,
				NSLocalizedString(@"Update", @"Installer Main"), kUIButtonBarButtonTitle,
				@"0", kUIButtonBarButtonType,
			nil],
			[NSDictionary dictionaryWithObjectsAndKeys:
				@"buttonBarItemTapped:", kUIButtonBarButtonAction,
				@"Uninstall.png", kUIButtonBarButtonInfo,
				@"UninstallSelected.png", kUIButtonBarButtonSelectedInfo,
				[NSNumber numberWithInt:4], kUIButtonBarButtonTag,
				self, kUIButtonBarButtonTarget,
				NSLocalizedString(@"Uninstall", @"Installer Main"), kUIButtonBarButtonTitle,
				@"0", kUIButtonBarButtonType,
			nil],
			[NSDictionary dictionaryWithObjectsAndKeys:
				@"buttonBarItemTapped:", kUIButtonBarButtonAction,
				@"Sources.png", kUIButtonBarButtonInfo,
				@"SourcesSelected.png", kUIButtonBarButtonSelectedInfo,
				[NSNumber numberWithInt:5], kUIButtonBarButtonTag,
				self, kUIButtonBarButtonTarget,
				NSLocalizedString(@"Sources", @"Installer Main"), kUIButtonBarButtonTitle,
				@"0", kUIButtonBarButtonType,
			nil],
		nil];	
}

- (void)applicationSuspend:(struct __GSEvent *)fp8 {
	if(!needsSuspend) {
		[super applicationSuspend:fp8];
	}
}

- (void)applicationWillTerminate {
	[packageManager restartSpringBoardIfNeeded];
}

/*- (BOOL)applicationIsReadyToSuspend {
	return NO;
}*/


#pragma mark -
#pragma mark Accessors

- (UIView *)mainView {
	return mainView;
}


#pragma mark -
#pragma mark Methods

- (BOOL)checkPermissions {
	if (geteuid() != 0)
	{
		UIAlertSheet * failAlert = [[UIAlertSheet alloc] init];
		[failAlert setTitle:NSLocalizedString(@"Insufficient Permissions", @"Installer Main")];
		[failAlert setBodyText:NSLocalizedString(@"Installer does not have the correct permissions set. Execute the commands: chown -R root:wheel /Applications/Installer.app and chmod 4755 /Applications/Installer.app/Installer to fix this.", @"Installer Main")];
		[failAlert addButtonWithTitle:NSLocalizedString(@"Exit", @"")];
		[failAlert setContext:@"Permissions"];
		[failAlert setDelegate:self];
		[failAlert popupAlertAnimated:YES];
		shouldShowProgressSheet = NO;
		shouldTerminate = YES;
	}
	
	return YES;
}

- (void)askToDonate {
	if(![preferences boolForKey:@"didDonate"]) {
		UIAlertSheet * failAlert = [[UIAlertSheet alloc] init];
		[failAlert setTitle:NSLocalizedString(@"Please Donate", @"Installer Main")];
		[failAlert setBodyText:NSLocalizedString(@"Installer represents many hours of hard work. If you find Installer useful, please consider donating to show your support.", @"Installer Main")];
		[failAlert addButtonWithTitle:NSLocalizedString(@"Donate Now", @"Installer Main")];
		[failAlert addButtonWithTitle:NSLocalizedString(@"Donate Later", @"Installer Main")];
		if([preferences boolForKey:@"didAsk"]) [failAlert addButtonWithTitle:NSLocalizedString(@"Already Donated", @"Installer Main")];
		[failAlert setContext:@"Donate"];
		[failAlert setDelegate:self];
		[failAlert popupAlertAnimated:YES];
	}
}

- (void)showProgressSheet {
	if(!progressSheetVisible) {
		progressSheetVisible = YES;
		[progressBar setProgress:0.0f];
		[progressSheet presentSheetInView:mainView];
		[progressSheet setBlocksInteraction:YES];
	}
}

- (void)hideProgressSheet {
	if(progressSheetVisible) {
		progressSheetVisible = NO;
		[progressSheet dismissAnimated:YES];
		[progressSheet setBlocksInteraction:YES];
	}
}

- (void)refresh {
	[self showProgressSheet];
	[self setStatusBarShowsProgress:YES];

	[packageManager refreshTrustedSources];

	if(![packageManager refreshAllSources]) {
		UIAlertSheet * failAlert = [[UIAlertSheet alloc] init];
		[failAlert setTitle:NSLocalizedString(@"Refresh Failed", @"Installer Main")];
		[failAlert setBodyText:NSLocalizedString(@"Could not refresh sources!", @"Installer Main")];
		[failAlert addButtonWithTitle:NSLocalizedString(@"OK", @"")];
		[failAlert setDelegate:self];
		[failAlert popupAlertAnimated:YES];
		shouldShowProgressSheet = NO;
	}

	[self setStatusBarShowsProgress:NO];
	[self hideProgressSheet];
	[self updateBadges];

	NSMutableDictionary * installerPackage = [[packageManager updateablePackages] packageWithBundleIdentifier:__INSTALLER_BUNDLE_IDENTIFIER__];
	if(installerPackage != nil) {
		UIAlertSheet * updateAlert = [[UIAlertSheet alloc] init];
		[updateAlert setTitle:NSLocalizedString(@"Installer Update", @"Installer Main")];
		[updateAlert setBodyText:NSLocalizedString(@"An Installer update is available, do you wish to update now?", @"Installer Main")];
		[updateAlert setDefaultButton:[updateAlert addButtonWithTitle:NSLocalizedString(@"Update Now", @"Installer Main")]];
		[updateAlert addButtonWithTitle:NSLocalizedString(@"Cancel", @"")];
		[updateAlert setDelegate:self];
		[updateAlert setContext:@"InstallerUpdate"];
		[updateAlert popupAlertAnimated:YES];
		shouldShowProgressSheet = NO;
	}
}

- (void)refreshOneSource:(NSDictionary*)source {
	[self showProgressSheet];
	[self setStatusBarShowsProgress:YES];

	[packageManager refreshTrustedSources];

	if(![packageManager refreshSource:source]) {
		UIAlertSheet * failAlert = [[UIAlertSheet alloc] init];
		[failAlert setTitle:NSLocalizedString(@"Refresh Failed", @"Installer Main")];
		[failAlert setBodyText:NSLocalizedString(@"Could not refresh sources!", @"Installer Main")];
		[failAlert addButtonWithTitle:NSLocalizedString(@"OK", @"")];
		[failAlert setDelegate:self];
		[failAlert popupAlertAnimated:YES];
		shouldShowProgressSheet = NO;
	}

	[self setStatusBarShowsProgress:NO];
	[self hideProgressSheet];
	[self updateBadges];

	NSMutableDictionary * installerPackage = [[packageManager updateablePackages] packageWithBundleIdentifier:__INSTALLER_BUNDLE_IDENTIFIER__];
	if(installerPackage != nil) {
		UIAlertSheet * updateAlert = [[UIAlertSheet alloc] init];
		[updateAlert setTitle:NSLocalizedString(@"Installer Update", @"Installer Main")];
		[updateAlert setBodyText:NSLocalizedString(@"An Installer update is available, do you wish to update now?", @"Installer Main")];
		[updateAlert setDefaultButton:[updateAlert addButtonWithTitle:NSLocalizedString(@"Update Now", @"Installer Main")]];
		[updateAlert addButtonWithTitle:NSLocalizedString(@"Cancel", @"")];
		[updateAlert setDelegate:self];
		[updateAlert setContext:@"InstallerUpdate"];
		[updateAlert popupAlertAnimated:YES];
		shouldShowProgressSheet = NO;
	}
}


- (void)updateBadges {
	unsigned availableUpdateCount = [[packageManager updateablePackages] count];

	if(availableUpdateCount > 0) {
		NSString * badge = [NSString stringWithFormat:@"%i", availableUpdateCount];
		[buttonBar setBadgeValue:badge forButton:3];
		[self setApplicationBadge:badge];
	} else {
		[buttonBar setBadgeValue:nil forButton:3];
		[self setApplicationBadge:nil];
	}
}


#pragma mark -
#pragma mark ButtonBar Delegate

- (void)buttonBarItemTapped:(id)sender {
	ATController * controller = nil;

	switch([sender tag]) {
		case 1:
			controller = featuredController;
			break;

		case 2:
			controller = installController;
			break;

		case 3:
			controller = updateController;
			break;

		case 4:
			controller = uninstallController;
			break;

		case 5:
			controller = sourcesController;
			break;
	}

	if(controller != keyController) {
		[contentView transition:0 toView:[controller view]];
		[keyController controllerDidLoseKey];
		keyController = controller;
	}

	[keyController controllerDidBecomeKey];
	[buttonBar showSelectionForButton:[sender tag]];
}

- (void)switchToPackageWithIdentifier:(NSString *)identifier {
	NSDictionary * package = nil;
	int button = 0;
	ATController * controller = nil;

	if(package = [[packageManager installablePackages] packageWithBundleIdentifier:identifier]) {
		button = 2;
		controller = installController;
	} else if(package = [[packageManager updateablePackages] packageWithBundleIdentifier:identifier]) {
		button = 3;
		controller = updateController;
	} else if(package = [[packageManager uninstallablePackages] packageWithBundleIdentifier:identifier]) {
		button = 4;
		controller = uninstallController;
	}

        if(button > 0) {
                [contentView transition:0 toView:[controller view]];
                [keyController controllerDidLoseKey];

                keyController = controller;
        	[keyController controllerDidBecomeKey];
	        [buttonBar showSelectionForButton:button];
		[controller showPackage:package];
	}
}


#pragma mark -
#pragma mark ATPackageManager Delegate

- (void)packageManager:(ATPackageManager *)aPackageManager startedQueue:(NSArray *)queue {
	[self showProgressSheet];
	[self setStatusBarShowsProgress:YES];
	canContinue = YES;
	shouldShowProgressSheet = YES;
	needsSuspend = YES;
}

- (void)packageManager:(ATPackageManager *)aPackageManager progressChanged:(NSNumber *)progress {
	[progressBar setProgress:[progress doubleValue] / 100.0f];
	[[NSRunLoop currentRunLoop] runUntilDate:[NSDate date]];
}

- (void)packageManager:(ATPackageManager *)aPackageManager statusChanged:(NSString *)status {
	[progressSheet setTitle:NSLocalizedString(status, @"")];
	[[NSRunLoop currentRunLoop] runUntilDate:[NSDate date]];
}

- (void)packageManager:(ATPackageManager *)aPackageManager finishedQueueWithResult:(NSString *)aResult {
	[keyController packageManagerFinishedQueueWithResult:aResult];
	[self setStatusBarShowsProgress:NO];

	[self updateBadges];
	[self hideProgressSheet];
	needsSuspend = NO;

	if(needsRestart) {
		UIAlertSheet * updatedAlert = [[UIAlertSheet alloc] init];
		[updatedAlert setTitle:NSLocalizedString(@"Installer Updated", @"Installer Main")];
		[updatedAlert setBodyText:NSLocalizedString(@"Installer was updated, you will need to restart Instaler.", @"Installer Main")];
		[updatedAlert addButtonWithTitle:NSLocalizedString(@"OK", @"")];
		[updatedAlert setDelegate:self];
		[updatedAlert popupAlertAnimated:YES];
		shouldShowProgressSheet = NO;
		shouldTerminate = YES;
	}
}

- (void)packageManager:(ATPackageManager *)aPackageManager didAddSource:(NSMutableDictionary *)aSource {
}

- (void)packageManager:(ATPackageManager *)aPackageManager didRemoveSource:(NSMutableDictionary *)aSource {
}

- (void)packageManager:(ATPackageManager *)aPackageManager issuedNotice:(NSString *)aNotice {
	canContinue = NO;
	shouldShowProgressSheet = YES;

	[self hideProgressSheet];

	UIAlertSheet * noticeAlert = [[UIAlertSheet alloc] init];
	[noticeAlert setTitle:NSLocalizedString(@"Notice", @"Installer Main")];
	[noticeAlert setBodyText:aNotice];
	[noticeAlert addButtonWithTitle:NSLocalizedString(@"OK", @"")];
	[noticeAlert setDelegate:self];
	[noticeAlert setBlocksInteraction:YES];

	[noticeAlert popupAlertAnimated:YES];
}

- (void)packageManager:(ATPackageManager *)aPackageManager issuedError:(NSString *)anError {
	canContinue = NO;
	shouldShowProgressSheet = NO;

	[self hideProgressSheet];

	UIAlertSheet * errorAlert = [[UIAlertSheet alloc] init];
	[errorAlert setTitle:NSLocalizedString(@"Error", @"Installer Main")];
	[errorAlert setBodyText:NSLocalizedString(anError, @"")];
	[errorAlert addButtonWithTitle:NSLocalizedString(@"OK", @"")];
	[errorAlert setDelegate:self];
	[errorAlert setBlocksInteraction:YES];
	[errorAlert popupAlertAnimated:YES];
}

- (NSNumber *)packageManagerCanContinue:(ATPackageManager *)aPackageManager {
	return [NSNumber numberWithBool:canContinue];
}

- (void)packageManager:(ATPackageManager *)aPackageManager confirm:(NSArray *)arguments {
	canContinue = NO;
	shouldShowProgressSheet = YES;

	[self hideProgressSheet];

	UIAlertSheet * confirmAlert = [[UIAlertSheet alloc] init];
	[confirmAlert setTitle:NSLocalizedString(@"Confirmation", @"Installer Main")];
	[confirmAlert setBodyText:[arguments objectAtIndex:0]];
	[confirmAlert addButtonWithTitle:[arguments objectAtIndex:1]];
	[confirmAlert addButtonWithTitle:[arguments objectAtIndex:2]];
	[confirmAlert setDelegate:self];
	[confirmAlert setBlocksInteraction:YES];
	[confirmAlert popupAlertAnimated:YES];
}

- (NSNumber *)packageManagerConfirmedButton:(ATPackageManager *)aPackageManager {
	return [NSNumber numberWithUnsignedInt:confirmedButton];
}


#pragma mark -
#pragma mark UIAlertSheet Delegate
                
- (void)alertSheet:(id)sheet buttonClicked:(int)button {
	confirmedButton = button;

	[sheet dismissAnimated:YES];

	if([[sheet context] isEqualToString:@"InstallerUpdate"] && button == 1) {
		needsRestart = YES;
		NSMutableDictionary * installerUpdate = [[packageManager updateablePackages] packageWithBundleIdentifier:__INSTALLER_BUNDLE_IDENTIFIER__];
		[packageManager clearQueue];
		[packageManager queuePackage:installerUpdate forOperation:__UPDATE_OPERATION__];
		[packageManager processQueue];
	} else if([[sheet context] isEqualToString:@"Donate"]) {
		[preferences setValue:[NSNumber numberWithBool:YES] forKey:@"didAsk"];
		if(button == 1) [self openURL:[NSURL URLWithString:@"https://www.paypal.com/xclick/business=paypal%40nullriver%2ecom&item_name=AppTapp&item_number=apptapp&no_shipping=0&no_note=1&tax=0&currency_code=USD"]];
		else if(button == 3) [preferences setValue:[NSNumber numberWithBool:YES] forKey:@"didDonate"];
	} else if([[sheet context] isEqualToString:@"Permissions"]) {
		// we do nothing
	} else {
		if(shouldShowProgressSheet && button == 1) [self showProgressSheet];
		canContinue = YES;
	}

	if(shouldTerminate) [self performSelector:@selector(terminate) withObject:nil afterDelay:0.5f];

	[sheet autorelease];
}

@end
