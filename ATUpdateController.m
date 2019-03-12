// AppTapp Installer
// Copyright 2007 Nullriver, Inc.

#import "ATUpdateController.h"


@implementation ATUpdateController

#pragma mark -
#pragma mark Factory

- (id)initInView:(UITransitionView *)aView withTitle:(NSString *)aTitle {
	if((self = [super initInView:aView withTitle:aTitle])) {
		packages = [[NSMutableArray alloc] init];
		categories = [[NSMutableArray alloc] init];

		if([[packageManager updateablePackages] count] > 0) [navBar showButtonsWithLeftTitle:nil rightTitle:NSLocalizedString(@"Update All", @"Update")];

		sectionList = [[UISectionList alloc] initWithFrame:[self contentFrame] showSectionIndex:NO];
		[sectionList setDataSource:self];
		[sectionList setAllowsScrollIndicators:YES];
		[sectionList setShouldHideHeaderInShortLists:YES];

		table = [sectionList table];
		[table setDelegate:self];
		[table addTableColumn:[[[UITableColumn alloc] initWithTitle:NSLocalizedString(@"Sources", @"Sources") identifier:@"sources" width:320.0f] autorelease]];
		[table setDelegate:self];
		[table setSeparatorStyle:1];
		[table setRowHeight:56.0f];

		packageDataSource = [[ATPackageDataSource alloc] init];

		detailTable = [[UIPreferencesTable alloc] initWithFrame:[self contentFrame]];
		[detailTable setDelegate:self];
		[detailTable setDataSource:packageDataSource];
		[detailTable setScrollerIndicatorSubrect:CGRectMake(310.0f, 0.0f, 10.0f, 480.0f - 43.0f - 49.0f - 11.0f)];

		[contentView transition:0 toView:sectionList];
	}

	return self;
}

- (void)dealloc {
	[packages release];
	[categories release];
	[sectionList release];
	[packageDataSource release];
	[detailTable release];

	[super dealloc];
}


#pragma mark -
#pragma mark Methods

- (void)controllerDidBecomeKey {
	[super controllerDidBecomeKey];
	[self refresh];
	[table setOffset:CGPointMake(0.0f, 0.0f)];
}

- (void)packageManagerFinishedQueueWithResult:(NSString *)aResult {
	[self controllerDidBecomeKey];
}

- (void)refresh {
	[packages removeAllObjects];
	[packages addObjectsFromArray:[packageManager updateablePackages]];
	[packages sortUsingSelector:@selector(comparePackageDate:)];

	//[categories removeAllObjects];
	//[categories addObjectsFromArray:[packages packageDates]];

	if([packages count] > 0) [navBar showButtonsWithLeftTitle:nil rightTitle:NSLocalizedString(@"Update All", @"Update")];
	else [navBar showButtonsWithLeftTitle:nil rightTitle:nil];

	[sectionList reloadData];
}

- (void)showPackage:(NSDictionary *)aPackage {
        [packageDataSource setSelectedPackage:aPackage];
        [navBar pushNavigationItem:[[[UINavigationItem alloc] initWithTitle:NSLocalizedString(@"Package", @"Package Info")] autorelease]];
}


#pragma mark -
#pragma mark UINavigationBar Delegate

- (void)navigationBar:(id)aNavBar pushedItem:(id)aNavItem {
	int level = [[navBar navigationItems] count];
	NSMutableDictionary * selectedPackage = [packageDataSource selectedPackage];

	if(level == 1) { // Initial push
		[navBar showButtonsWithLeftTitle:nil rightTitle:nil];
		// No transition necessary here
	} else if(level == 2) { // Package details
		[detailTable setOffset:CGPointMake(0.0f, 0.0f)];
		[detailTable reloadData];

		if([selectedPackage isUpdateablePackage]) [navBar showButtonsWithLeftTitle:nil rightTitle:NSLocalizedString(@"Update", @"Update")];
		else [navBar showButtonsWithLeftTitle:nil rightTitle:nil];
		[contentView transition:1 toView:detailTable];
	} else if(level == 3) { // More info
		UIWebView * infoWebView = [packageDataSource infoWebView];
		UIScroller * infoScroller = [packageDataSource infoScroller];

		[infoScroller setFrame:[self contentFrame]];
		[infoWebView setFrame:[self contentFrame]];

		[infoScroller scrollPointVisibleAtTopLeft:CGPointMake(0.0f, 0.0f)];
		[infoWebView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"about:blank"]]];
		[infoWebView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:[selectedPackage packageURL]]]];

		[navBar showButtonsWithLeftTitle:nil rightTitle:nil];
		[contentView transition:1 toView:infoScroller];
	}
}

- (void)navigationBar:(id)aNavBar poppedItem:(id)aNavItem {
	int level = [[navBar navigationItems] count];
	int transition = [navBar isAnimationEnabled] ? 2 : 0;

	if(level == 1) { // Back to root
		if([packages count] > 0) [navBar showButtonsWithLeftTitle:nil rightTitle:NSLocalizedString(@"Update All", @"Update")];
		else [navBar showButtonsWithLeftTitle:nil rightTitle:nil];
		[table selectRow:NSNotFound byExtendingSelection:NO];
		[contentView transition:transition toView:sectionList];
	} else if(level == 2) { // Back to package details
		NSMutableDictionary * selectedPackage = [packageDataSource selectedPackage];
		if([selectedPackage isUpdateablePackage]) [navBar showButtonsWithLeftTitle:nil rightTitle:NSLocalizedString(@"Update", @"Update")];
		else [navBar showButtonsWithLeftTitle:nil rightTitle:nil];
		[detailTable selectRow:NSNotFound byExtendingSelection:NO];
		[contentView transition:transition toView:detailTable];
	}
}

- (void)navigationBar:(id)aNavBar buttonClicked:(int)button {
	int level = [[navBar navigationItems] count];

	if(level == 1) { // Update All
		UIAlertSheet * updateAlert = [[UIAlertSheet alloc] init];
		[updateAlert setTitle:NSLocalizedString(@"Update all packages?", @"Update")];

		if(![packages allPackagesAreTrusted]) {
			[updateAlert setBodyText:NSLocalizedString(@"One or more of the updated packages come from an untrusted source and may be unsafe to update!", @"Update")];
			[updateAlert setDestructiveButton:[updateAlert addButtonWithTitle:NSLocalizedString(@"Update All", @"Update")]];
		} else {
			[updateAlert addButtonWithTitle:NSLocalizedString(@"Update All", @"Update")];
		}

		[updateAlert setDefaultButton:[updateAlert addButtonWithTitle:NSLocalizedString(@"Cancel", @"")]];
		[updateAlert setDelegate:self];
		[updateAlert setAlertSheetStyle:2];
		//[updateAlert setRunsModal:YES];
		[updateAlert setBlocksInteraction:YES];
		[updateAlert presentSheetInView:[[ATInstaller sharedInstaller] mainView]];
	} else if(level == 2) { // Update
		NSMutableDictionary * selectedPackage = [packageDataSource selectedPackage];

		UIAlertSheet * updateAlert = [[UIAlertSheet alloc] init];
		[updateAlert setTitle:[NSString stringWithFormat:@"%@ %@", [selectedPackage packageName], [selectedPackage packageVersion]]];

		if(![[selectedPackage packageSource] isTrustedSource]) {
			[updateAlert setBodyText:NSLocalizedString(@"This package comes from an untrusted source and may be unsafe to update!", @"Update")];
			[updateAlert setDestructiveButton:[updateAlert addButtonWithTitle:NSLocalizedString(@"Update", @"Update")]];
		} else {
			[updateAlert addButtonWithTitle:NSLocalizedString(@"Update", @"Update")];
		}

		if([packageManager queueContainsPackage:selectedPackage]) {
			[updateAlert addButtonWithTitle:NSLocalizedString(@"Remove from Queue", @"Installer Main")];
		} else {
			[updateAlert addButtonWithTitle:NSLocalizedString(@"Add to Queue", @"Installer Main")];
		}
                
		if([packageManager hasQueuedPackages]) {
			[updateAlert addButtonWithTitle:NSLocalizedString(@"Clear Queue", @"Installer Main")];
		}

		[updateAlert setDefaultButton:[updateAlert addButtonWithTitle:NSLocalizedString(@"Cancel", @"")]];
		[updateAlert setDelegate:self];
		[updateAlert setAlertSheetStyle:2];
		//[updateAlert setRunsModal:YES];
		[updateAlert setBlocksInteraction:YES];
		[updateAlert presentSheetInView:[[ATInstaller sharedInstaller] mainView]];
	}
}


#pragma mark -
#pragma mark UISectionList Delegate

- (int)numberOfSectionsInSectionList:(UISectionList *)aSectionList {
	return 1; //[categories count];
}

- (NSString *)sectionList:(UISectionList *)aSectionList titleForSection:(int)row {
	return NSLocalizedString(@"Available Updates", @"Update"); //[categories objectAtIndex:row];
}

- (int)sectionList:(UISectionList *)aSectionList rowForSection:(int)row {
	return 0; //[packages indexOfPackageDate:[categories objectAtIndex:row]];
}


#pragma mark -
#pragma mark UITable Delegate

- (int)numberOfRowsInTable:(UITable *)aTable {
	return [packages count];
}

- (id)table:(UITable *)aTable cellForRow:(int)row column:(UITableColumn *)aColumn {
	ATDetailCell * cell = [[ATDetailCell alloc] init];

	NSMutableDictionary * package = [packages objectAtIndex:row];

	NSString * iconName = @"Package.png";
	if([package isNewPackage]) iconName = @"PackageNew.png";
	[cell setIcon:[UIImage imageNamed:iconName]];
	[cell setTitle:[package packageName]];
	[cell setSubtitle:[NSString stringWithFormat:NSLocalizedString(@"Version %@", @"Package Info"), [package packageVersion]]];

	return [cell autorelease];
}

- (BOOL)table:(UITable *)aTable showDisclosureForRow:(int)row {
	if(aTable == table) return YES;
	else return NO;
}

- (void)tableSelectionDidChange:(NSNotification *)aNotification {
	UITable * aTable = [aNotification valueForKey:@"object"];
	int row = [aTable selectedRow];
	id cell = [aTable cellAtRow:[aTable selectedRow] column:0];

	if([aTable selectedRow] != NSNotFound) {
		if(aTable == table) {
			[packageDataSource setSelectedPackage:[packages objectAtIndex:row]];
			[navBar pushNavigationItem:[[[UINavigationItem alloc] initWithTitle:NSLocalizedString(@"Package", @"Package Info")] autorelease]];
		} else if(aTable  == detailTable) {
			if([[cell title] isEqualToString:NSLocalizedString(@"Contact", @"Package Info")]) {
				NSString * subject = [[NSString stringWithFormat:@"Regarding AppTapp package \"%@\"", [[packageDataSource selectedPackage] packageName]] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
				NSURL * contactURL = [NSURL URLWithString:[NSString stringWithFormat:@"mailto:%@?subject=%@", [[packageDataSource selectedPackage] packageContact], subject]];
				[detailTable selectRow:NSNotFound byExtendingSelection:NO];
				if(contactURL != nil) [[ATInstaller sharedInstaller] openURL:contactURL];;
			} else if([[cell title] isEqualToString:NSLocalizedString(@"More Info", @"Package Info")]) {
				[navBar pushNavigationItem:[[[UINavigationItem alloc] initWithTitle:NSLocalizedString(@"More Info", @"Package Info")] autorelease]];
			}
		}
	}
}


#pragma mark -
#pragma mark UIAlertSheet Delegate

- (void)alertSheet:(id)sheet buttonClicked:(int)button {
	int level = [[navBar navigationItems] count];

	[sheet dismissAnimated:YES];
	[sheet autorelease];
 
	if(level == 1) {
		if(button == 1) {
			[packageManager clearQueue];

			NSEnumerator * allPackages = [packages reverseObjectEnumerator];
			id package;

			while((package = [allPackages nextObject])) {
				[packageManager queuePackage:package forOperation:__UPDATE_OPERATION__];
			}
			[packageManager processQueue];
		}
	} else if(level == 2) {
		NSMutableDictionary * selectedPackage = [packageDataSource selectedPackage];

		switch(button) {
			case 1:
				[packageManager queuePackage:selectedPackage forOperation:__UPDATE_OPERATION__];
				[packageManager processQueue];
				break;

			case 2:
				if([packageManager queueContainsPackage:selectedPackage]) { 
					[packageManager dequeuePackage:selectedPackage];
				} else {
					[packageManager queuePackage:selectedPackage forOperation:__UPDATE_OPERATION__];
				}
				[navBar performSelector:@selector(popNavigationItem) withObject:nil afterDelay:0.5f];
				break;

			case 3:
				[packageManager clearQueue];
				break;
		}
	}
}
 
@end
