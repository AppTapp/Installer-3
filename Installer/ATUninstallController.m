// AppTapp Installer
// Copyright 2007 Nullriver, Inc.

#import "ATUninstallController.h"


@implementation ATUninstallController

#pragma mark -
#pragma mark Factory

- (id)initInView:(UITransitionView *)aView withTitle:(NSString *)aTitle {
	if((self = [super initInView:aView withTitle:aTitle])) {
		packages = [[NSMutableArray alloc] init];
		categories = [[NSMutableArray alloc] init];
		packagesMaster = [[NSMutableArray alloc] init];

		CGRect packageSectionListRect = [self contentFrame];
		packageSectionListRect.size.height -= 48;
		packageSectionListRect.origin.y += 48;

		sectionList = [[UISectionList alloc] initWithFrame:packageSectionListRect showSectionIndex:NO];
		[sectionList setDataSource:self];
		[sectionList setAllowsScrollIndicators:YES];
		[sectionList setShouldHideHeaderInShortLists:NO];

		CGRect searchFieldRect = packageSectionListRect;
		searchFieldRect.size.height = [UISearchField defaultHeight];
		searchFieldRect.origin.y -= 40;
		searchFieldRect.origin.x += 10;
		searchFieldRect.size.width -= 20;
		
		searchField = [[UISearchField alloc] initWithFrame:searchFieldRect];
		[searchField setLabel:NSLocalizedString(@"Search", @"Install Table")];
		[searchField setPreferredKeyboardType:0];
		[searchField setClearButtonStyle:1];
		[searchField setReturnKeyType:6];
		[searchField setDelegate:self];
		[searchField setEditingDelegate:self];
		
		struct __GSFont* font = [NSClassFromString(@"WebFontCache") createFontWithFamily:@"Helvetica" traits:0 size:24.];
		[searchField setFont:font];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(searchTextChanged:) name:@"UITextFieldTextDidChangeNotification" object:searchField];
		[searchField setPaddingTop:5. paddingLeft:4.];
		[searchField setAutoCorrectionType:1];	// no autocorrection

		packageView = [[UIView alloc] initWithFrame:[self contentFrame]];
		[packageView addSubview:searchField];
		[packageView addSubview:sectionList];

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


		[UIKeyboard initImplementationNow];
		
		animator = [[UIAnimator alloc] init];
		
		CGRect kbdSize = [UIHardware fullScreenApplicationContentRect];
		kbdSize.size = [UIKeyboard defaultSize];
		kbdSize.origin.y = [[[ATInstaller sharedInstaller] mainView] frame].size.height;
		
		mTableRectWithoutKeyboard = packageSectionListRect;
		mTableRectWithKeyboard = packageSectionListRect;
		mTableRectWithKeyboard.size.height -= [UIKeyboard defaultSize].height - ([[[ATInstaller sharedInstaller] mainView] frame].size.height - [self contentFrame].size.height - packageSectionListRect.origin.y) - 4;

		keyboard = [[UIKeyboard alloc] initWithFrame:kbdSize];

		[contentView transition:0 toView:packageView];
	}

	return self;
}

- (void)dealloc {
	[packages release];
	[packagesMaster release];
	[categories release];
	[sectionList release];
	[packageView release];
	[packageDataSource release];
	[detailTable release];

	[super dealloc];
}

#pragma mark -
#pragma mark Search Field Methods

- (void)textFieldDidBecomeFirstResponder:(id)textField
{
	[[[ATInstaller sharedInstaller] mainView] addSubview:keyboard];
	
	UITransformAnimation * animation = [[[UITransformAnimation alloc] initWithTarget:keyboard] autorelease];
	[animation setStartTransform: CGAffineTransformMake(1,0,0,1,0,0)];
	[animation setEndTransform:CGAffineTransformMakeTranslation(0, -[UIKeyboard defaultSize].height)];
	[animator addAnimation:animation withDuration:0.2f start:YES];
	[keyboard activate];
		
	[sectionList setFrame:mTableRectWithKeyboard];
}

- (void)textFieldDidResignFirstResponder:(id)textField
{
	UITransformAnimation * animation = [[[UITransformAnimation alloc] initWithTarget:keyboard] autorelease];
	[animation setStartTransform:CGAffineTransformMakeTranslation(0, -[UIKeyboard defaultSize].height)];
	[animation setEndTransform: CGAffineTransformMake(1,0,0,1,0,0)];
	[animator addAnimation:animation withDuration:0.2f start:YES];

	[keyboard deactivate];
	[sectionList setFrame:mTableRectWithoutKeyboard];
	
	if (!mDontClearSearch)
	{
		[searchField setText:@""];
		[self _refilterPackages];
	}
	else
		mDontClearSearch = NO;
}

- (void)searchTextChanged:(NSNotification*)notification
{
	[self _refilterPackages];
}

- (BOOL) keyboardInput:(id) editor shouldInsertText:(NSString *) text isMarkedText:(BOOL) marked {
	if([text length] == 1 && [text characterAtIndex:0] == '\n') {
		mDontClearSearch = YES;
		[searchField resignFirstResponder];
		return NO;
	}
	return YES;
}

- (int) keyboardInput:(id) editor positionForAutocorrection:(id) autoCorrection {
	return -1;
}

- (void)textFieldClearButtonPressed:(id)textField
{
	// The whole reason we do the delayed perform is because -(void)[UITextField _clearButtonClicked:](id): calls becomeFirstResponder right after this delegate call, which effectively negates our effort to resign the responder state. So putting it into the delayed notification queue will make it execute when we fall down to the runloop. Ugh. :)
	[searchField performSelector:@selector(resignFirstResponder) withObject:nil afterDelay:0.01];
}

#pragma mark -
#pragma mark Methods

- (void)controllerDidBecomeKey {
	[super controllerDidBecomeKey];
	[searchField resignFirstResponder];
	[self refresh];
	[table setOffset:CGPointMake(0.0f, 0.0f)];
}

- (void)refresh {
	[packagesMaster removeAllObjects];
	[packagesMaster addObjectsFromArray:[packageManager uninstallablePackages]];
	[packagesMaster sortUsingSelector:@selector(caseInsensitiveComparePackageCategory:)];
	[self _refilterPackages];

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
		[searchField resignFirstResponder];
		[navBar showButtonsWithLeftTitle:nil rightTitle:nil];
		// No transition necessary here
	} else if(level == 2) { // Package details
		[detailTable setOffset:CGPointMake(0.0f, 0.0f)];
		[detailTable reloadData];

		if([selectedPackage isUninstallablePackage]) [navBar showButtonsWithLeftTitle:nil rightTitle:NSLocalizedString(@"Uninstall", @"Uninstall")];
		else [navBar showButtonsWithLeftTitle:nil rightTitle:NSLocalizedString(@"Reinstall", @"Uninstall")];
		[searchField resignFirstResponder];
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
		[self refresh];
		[navBar showButtonsWithLeftTitle:nil rightTitle:nil];
		[table selectRow:NSNotFound byExtendingSelection:NO];
		[searchField resignFirstResponder];
		[contentView transition:transition toView:packageView];
	} else if(level == 2) { // Back to package details
		NSMutableDictionary * selectedPackage = [packageDataSource selectedPackage];
		if([selectedPackage isUninstallablePackage]) [navBar showButtonsWithLeftTitle:nil rightTitle:NSLocalizedString(@"Uninstall", @"Uninstall")];
		else [navBar showButtonsWithLeftTitle:nil rightTitle:NSLocalizedString(@"Reinstall", @"Uninstall")];
		[detailTable selectRow:NSNotFound byExtendingSelection:NO];
		[searchField resignFirstResponder];
		[contentView transition:transition toView:detailTable];
	}
}

- (void)navigationBar:(id)aNavBar buttonClicked:(int)button {
	int level = [[navBar navigationItems] count];

	if(level == 2) {
		NSMutableDictionary * selectedPackage = [packageDataSource selectedPackage];

		UIAlertSheet * uninstallAlert = [[UIAlertSheet alloc] init];
		[uninstallAlert setTitle:[NSString stringWithFormat:@"%@ %@", [selectedPackage packageName], [selectedPackage packageVersion]]];
		if([selectedPackage isUninstallablePackage]) [uninstallAlert addButtonWithTitle:NSLocalizedString(@"Uninstall", @"Uninstall")];
		else [uninstallAlert addButtonWithTitle:NSLocalizedString(@"Reinstall", @"Uninstall")];

		if([packageManager queueContainsPackage:selectedPackage]) {
			[uninstallAlert addButtonWithTitle:NSLocalizedString(@"Remove from Queue", @"Installer Main")];
		} else {
			[uninstallAlert addButtonWithTitle:NSLocalizedString(@"Add to Queue", @"Installer Main")];
		}
                
		if([packageManager hasQueuedPackages]) {
			[uninstallAlert addButtonWithTitle:NSLocalizedString(@"Clear Queue", @"Installer Main")];
		}

		[uninstallAlert setDefaultButton:[uninstallAlert addButtonWithTitle:NSLocalizedString(@"Cancel", @"")]];
		[uninstallAlert setDelegate:self];
		[uninstallAlert setAlertSheetStyle:2];
		[uninstallAlert setBlocksInteraction:YES];
		[uninstallAlert presentSheetInView:[[ATInstaller sharedInstaller] mainView]];
	}
}


#pragma mark -
#pragma mark UISectionList Delegate

- (int)numberOfSectionsInSectionList:(UISectionList *)aSectionList {
	return [categories count];
}

- (NSString *)sectionList:(UISectionList *)aSectionList titleForSection:(int)row {
	return [categories objectAtIndex:row];
}

- (int)sectionList:(UISectionList *)aSectionList rowForSection:(int)row {
	return [packages indexOfPackageCategory:[categories objectAtIndex:row]];
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
				if(contactURL != nil) [[ATInstaller sharedInstaller] openURL:contactURL];
			} else if([[cell title] isEqualToString:NSLocalizedString(@"More Info", @"Package Info")]) {
				[navBar pushNavigationItem:[[[UINavigationItem alloc] initWithTitle:NSLocalizedString(@"More Info", @"Package Info")] autorelease]];
			}
		}
	}
}


#pragma mark -
#pragma mark Alert Sheet Delegate

- (void)alertSheet:(id)sheet buttonClicked:(int)button {
	[sheet dismissAnimated:YES];
	[sheet autorelease];
 
	NSMutableDictionary * selectedPackage = [packageDataSource selectedPackage];

	switch(button) {
		case 1:
			if([selectedPackage isUninstallablePackage]) [packageManager queuePackage:selectedPackage forOperation:__UNINSTALL_OPERATION__];
			else [packageManager queuePackage:selectedPackage forOperation:__UPDATE_OPERATION__];
			[packageManager processQueue];
			break;

		case 2:
			if([packageManager queueContainsPackage:selectedPackage]) {
				[packageManager dequeuePackage:selectedPackage];
			} else {
				if([selectedPackage isUninstallablePackage]) [packageManager queuePackage:selectedPackage forOperation:__UNINSTALL_OPERATION__];
				else [packageManager queuePackage:selectedPackage forOperation:__UPDATE_OPERATION__];
			}
			[navBar performSelector:@selector(popNavigationItem) withObject:nil afterDelay:0.5f];
			break;

		case 3:
			[packageManager clearQueue];
			break;
	}
}

#pragma mark -
#pragma mark Sections

- (void)_refilterPackages
{
	NSString* filterString = [searchField text];
	
	[packages removeAllObjects];
	
	if (!filterString || ![filterString length])
	{
		[packages addObjectsFromArray:packagesMaster];
	}
	else
	{
		int i;
		int max = [packagesMaster count];		// so we don't repoll on every loop iteration
		for (i=0;i < max; i++)
		{
			if ([[[packagesMaster objectAtIndex:i] packageName] rangeOfString:filterString options:(NSCaseInsensitiveSearch)].length)
				[packages addObject:[packagesMaster objectAtIndex:i]];
		}
	}

	[categories removeAllObjects];
	[categories addObjectsFromArray:[packages packageCategories]];

	[sectionList reloadData];
}

 
@end
