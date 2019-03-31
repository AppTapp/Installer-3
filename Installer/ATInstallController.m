// AppTapp Installer
// Copyright 2007 Nullriver, Inc.

#import "ATInstallController.h"
#import "ATInstaller.h"


@implementation ATInstallController

#pragma mark -
#pragma mark Factory

- (id)initInView:(UITransitionView *)aView withTitle:(NSString *)aTitle {
	if((self = [super initInView:aView withTitle:aTitle])) {
		packages = [[NSMutableArray alloc] init];
		packagesMaster = [[NSMutableArray alloc] init];
		categories = [[NSMutableArray alloc] init];
		selectedCategory = 0;

		categoryTable = [[UITable alloc] initWithFrame:[self contentFrame]];
		[categoryTable setSeparatorStyle:1];
		[categoryTable setRowHeight:56.0f];
		[categoryTable addTableColumn:[[[UITableColumn alloc] initWithTitle:NSLocalizedString(@"Categories", @"Install Table") identifier:@"categories" width:320.0f] autorelease]];
		[categoryTable setDelegate:self];
		[categoryTable setDataSource:self];

		CGRect packageSectionListRect = [self contentFrame];
		packageSectionListRect.size.height -= 48;
		packageSectionListRect.origin.y += 48;
		
		packageSectionList = [[UISectionList alloc] initWithFrame:packageSectionListRect showSectionIndex:NO];
		[packageSectionList setDataSource:self];
		[packageSectionList setShouldHideHeaderInShortLists:NO];
		[packageSectionList setAllowsScrollIndicators:YES];
		
		packageTable = [packageSectionList table];
		//[packageTable setRightMargin:[packageSectionList marginForIndexControl:YES]];
		[packageTable setDelegate:self];
		[packageTable setSeparatorStyle:1];
		[packageTable setRowHeight:56.0f];
		[packageTable addTableColumn:[[[UITableColumn alloc] initWithTitle:NSLocalizedString(@"Packages", @"Install Table") identifier:@"packages" width:320.0f] autorelease]];
	
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
		[packageView addSubview:packageSectionList];

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

		keyboard = [[UIKeyboard alloc] initWithFrame:kbdSize];

		mTableRectWithoutKeyboard = packageSectionListRect;
		mTableRectWithKeyboard = packageSectionListRect;
		mTableRectWithKeyboard.size.height -= [UIKeyboard defaultSize].height - ([[[ATInstaller sharedInstaller] mainView] frame].size.height - [self contentFrame].size.height - packageSectionListRect.origin.y) - 4;
		
		[contentView transition:0 toView:categoryTable];
	}

	return self;
}

- (void)dealloc {
	[packages release];
	[packagesMaster release];
	[categories release];
	[categoryTable release];
	[packageSectionList release];
	[packageView release];
	[packageDataSource release];
	[detailTable release];
	[sections release];
	[keyboard release];
	[animator release];

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
	[packageSectionList setFrame:mTableRectWithKeyboard];
}

- (void)textFieldDidResignFirstResponder:(id)textField
{
	UITransformAnimation * animation = [[[UITransformAnimation alloc] initWithTarget:keyboard] autorelease];
	[animation setStartTransform:CGAffineTransformMakeTranslation(0, -[UIKeyboard defaultSize].height)];
	[animation setEndTransform: CGAffineTransformMake(1,0,0,1,0,0)];
	[animator addAnimation:animation withDuration:0.2f start:YES];
	//[keyboard removeFromSuperview];
	[keyboard deactivate];
	[packageSectionList setFrame:mTableRectWithoutKeyboard];
	
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
}

- (void)refresh {
	[packagesMaster removeAllObjects];
	[packagesMaster addObjectsFromArray:[packageManager installablePackages]];
	
	[self _refilterPackages];
	
	[categories removeAllObjects];
	[categories addObject:NSLocalizedString(@"All Packages", @"Install Table")];
	[categories addObject:NSLocalizedString(@"Recent Packages", @"Install Table")];
	[categories addObjectsFromArray:[packagesMaster packageCategories]];

	[categoryTable setOffset:CGPointMake(0.0f, 0.0f)];
	[categoryTable reloadData];
}

- (void)showPackage:(NSDictionary *)aPackage {
	selectedCategory = -1;
	selectedPackage = aPackage;
	[packageDataSource setSelectedPackage:selectedPackage];
	[navBar pushNavigationItem:[[[UINavigationItem alloc] initWithTitle:NSLocalizedString(@"Package", @"Install Table")] autorelease]];
}

- (void)reloadPackageTable {
	NSString * categoryTitle = [categories objectAtIndex:selectedCategory];

	if(selectedCategory == 0) { // All Packages
		[packagesMaster sortUsingSelector:@selector(caseInsensitiveComparePackageName:)];
	} else if(selectedCategory == 1) { // Recent Packages
		NSEnumerator * allPackages = [[[packagesMaster copy] autorelease] objectEnumerator];
		NSMutableDictionary * package;
		while((package = [allPackages nextObject])) { // Remove all old packages
			if(![package isNewPackage]) [packagesMaster removeObject:package];
		}

		[packagesMaster sortUsingSelector:@selector(comparePackageDate:)];
	} else { // A Category
		NSEnumerator * allPackages = [[[packagesMaster copy] autorelease] objectEnumerator];
		NSMutableDictionary * package;
		while((package = [allPackages nextObject])) { // Remove packages not in the right category
			if(![categoryTitle isEqualToString:[package packageCategory]]) [packagesMaster removeObject:package];
		}

		[packagesMaster sortUsingSelector:@selector(caseInsensitiveComparePackageName:)];				
	}
	
	// re-sort sections
	if (!sections)
		sections = [[NSMutableArray arrayWithCapacity:0] retain];

	[self _refilterPackages];
}

#pragma mark -
#pragma mark UINavigationBar Delegate

- (void)navigationBar:(id)aNavBar pushedItem:(id)aNavItem {
        int level = [[navBar navigationItems] count];

	if(selectedCategory == -1) level++;

        if(level == 1) { // Initial push
			[searchField resignFirstResponder];
		[navBar showButtonsWithLeftTitle:nil rightTitle:nil];
		// No transition necessary here
	} else if(level == 2) { // Packages for a specific category
		[self reloadPackageTable];
		[packageTable setOffset:CGPointMake(0.0f, 0.0f)];

		[navBar showButtonsWithLeftTitle:nil rightTitle:nil];
		[searchField resignFirstResponder];
		[contentView transition:1 toView:packageView];
	} else if(level == 3) { // Package details
		[detailTable setOffset:CGPointMake(0.0f, 0.0f)];
		[detailTable reloadData];

		if([selectedPackage isInstallablePackage]) [navBar showButtonsWithLeftTitle:nil rightTitle:NSLocalizedString(@"Install", @"Install Table")];
		else [navBar showButtonsWithLeftTitle:nil rightTitle:nil];
		
		[searchField resignFirstResponder];
		[contentView transition:1 toView:detailTable];
	} else if(level == 4) { // More info
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
		[packagesMaster removeAllObjects];
		[packagesMaster addObjectsFromArray:[packageManager installablePackages]];

		[navBar showButtonsWithLeftTitle:nil rightTitle:nil];
		[categoryTable selectRow:NSNotFound byExtendingSelection:NO];
		[searchField resignFirstResponder];
		[contentView transition:transition toView:categoryTable];
		selectedCategory = 0;
	} else if(level == 2) { // Packages for a specific category
		[navBar showButtonsWithLeftTitle:nil rightTitle:nil];
		[packageTable selectRow:NSNotFound byExtendingSelection:NO];
		[searchField resignFirstResponder];
		[contentView transition:transition toView:packageView];
	} else if(level == 3) { // Package details
		if([selectedPackage isInstallablePackage]) [navBar showButtonsWithLeftTitle:nil rightTitle:NSLocalizedString(@"Install", @"Install Table")];
		else [navBar showButtonsWithLeftTitle:nil rightTitle:nil];
		[detailTable selectRow:NSNotFound byExtendingSelection:NO];
		[searchField resignFirstResponder];
		[contentView transition:transition toView:detailTable];
	}
}

- (void)navigationBar:(id)aNavBar buttonClicked:(int)button {
	int level = [[navBar navigationItems] count];

	if(selectedCategory == -1) level++;

	if(level == 3) {
		UIAlertSheet * installAlert = [[UIAlertSheet alloc] init];
		[installAlert setTitle:[NSString stringWithFormat:@"%@ %@", [selectedPackage packageName], [selectedPackage packageVersion]]];

		if(![[selectedPackage packageSource] isTrustedSource]) {
			[installAlert setBodyText:NSLocalizedString(@"This package comes from an untrusted source, it may be unsafe to install!", @"Untrusted Source")];
			[installAlert setDestructiveButton:[installAlert addButtonWithTitle:NSLocalizedString(@"Install", @"Install Table")]];
		} else {
			[installAlert addButtonWithTitle:NSLocalizedString(@"Install", @"Install Table")];
		}

		if([packageManager queueContainsPackage:selectedPackage]) {
			[installAlert addButtonWithTitle:NSLocalizedString(@"Remove from Queue", @"Install Sheet")];
		} else {
			[installAlert addButtonWithTitle:NSLocalizedString(@"Add to Queue", @"Install Sheet")];
		}

		if([packageManager hasQueuedPackages]) {
			[installAlert addButtonWithTitle:NSLocalizedString(@"Clear Queue", @"Install Sheet")];
		}

		[installAlert setDefaultButton:[installAlert addButtonWithTitle:NSLocalizedString(@"Cancel", @"")]];
		[installAlert setDelegate:self];
		[installAlert setAlertSheetStyle:2];
		//[installAlert setRunsModal:YES];
		[installAlert setBlocksInteraction:YES];
		[installAlert presentSheetInView:[[ATInstaller sharedInstaller] mainView]];
	}
}


#pragma mark -
#pragma mark UITable Delegate / DataSource

- (int)numberOfRowsInTable:(UITable *)aTable {
	if(aTable == categoryTable) {
		return [categories count];
	} else if(aTable == packageTable) {
		return [packages count];
	}
}

- (id)table:(UITable *)aTable cellForRow:(int)row column:(UITableColumn *)aColumn {
	if(aTable == categoryTable) {
		UISimpleTableCell * cell = [[UISimpleTableCell alloc] init];

		[cell setIcon:[UIImage imageNamed:@"Category.png"]];
		[cell setTitle:[categories objectAtIndex:row]];

		if(row < 2) {
			[cell setIcon:[UIImage imageNamed:@"CategorySmart.png"]];
		}

		return [cell autorelease];
	} else if(aTable == packageTable) {
		ATDetailCell * cell = [[ATDetailCell alloc] init];

		NSMutableDictionary * package = [packages objectAtIndex:row];

		NSString * iconName = @"Package.png";
		if([package isNewPackage]) iconName = @"PackageNew.png";
		[cell setIcon:[UIImage imageNamed:iconName]];
		[cell setTitle:[package packageName]];

		NSString * subtitle = [package packageDescription] ? [package packageDescription] : [NSString stringWithFormat:NSLocalizedString(@"Version %@", @"Package Description"), [package packageVersion]];
		[cell setSubtitle:subtitle];

		return [cell autorelease];
	}

	return nil;
}

- (BOOL)table:(UITable *)aTable showDisclosureForRow:(int)row {
	if(aTable == categoryTable || aTable == packageTable) return YES;
	else if(aTable == detailTable && row == 7) {
		if([self preferencesTable:aTable numberOfRowsInGroup:0] == 7) return YES;
		else return NO;
	} else return NO;
}

- (void)tableSelectionDidChange:(NSNotification *)aNotification {
        UITable * aTable = [aNotification valueForKey:@"object"];
        int row = [aTable selectedRow];
	id cell = [aTable cellAtRow:[aTable selectedRow] column:0];

        if(aTable == categoryTable) {
		if([aTable selectedRow] != NSNotFound) {
			selectedCategory = row;
			[navBar pushNavigationItem:[[[UINavigationItem alloc] initWithTitle:NSLocalizedString(@"Packages", @"Install Table")] autorelease]];
		}
	} else if(aTable == packageTable) {
		if([aTable selectedRow] != NSNotFound) {
			selectedPackage = [packages objectAtIndex:row];
			[packageDataSource setSelectedPackage:selectedPackage];
			[navBar pushNavigationItem:[[[UINavigationItem alloc] initWithTitle:NSLocalizedString(@"Package", @"Install Table")] autorelease]];
		}
	} else if(aTable == detailTable) {
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

#pragma mark -
#pragma mark UISectionList DataSource

- (int)numberOfSectionsInSectionList:(UISectionList *)aSectionList {
	if(selectedCategory == 1) {
		return 3;
	} else {
		return [sections count];
	}
}

- (NSString *)sectionList:(UISectionList *)aSectionList titleForSection:(int)row {
	if (selectedCategory == 1) {
		switch(row) {
			case 0: return NSLocalizedString(@"Today", @"Recent Packages");
			case 1: return NSLocalizedString(@"Yesterday", @"Recent Packages");
			case 2: return NSLocalizedString(@"Older", @"Recent Packages");
		}
	} else {
		return [[sections objectAtIndex:row] objectForKey:@"n"];
//		return [categories objectAtIndex:selectedCategory];
	}
}

- (int)sectionList:(UISectionList *)aSectionList rowForSection:(int)row {
	if(selectedCategory == 1) {
		if(row == 0) return 0;

		NSEnumerator * allPackages = [packages objectEnumerator];
		NSMutableDictionary * package;
		int index = 0;

		while((package = [allPackages nextObject])) {
			if(row == 1 && [[package packageDate] timeIntervalSinceNow] < -24.0f * 60.0f * 60.0f) return index;
			if(row == 2 && [[package packageDate] timeIntervalSinceNow] < -48.0f * 60.0f * 60.0f) return index;
			index++;
		}
	} else {
		return [[[sections objectAtIndex:row] objectForKey:@"i"] intValue];
	}
}


#pragma mark -
#pragma mark Alert Sheet Delegate

- (void)alertSheet:(id)sheet buttonClicked:(int)button {
	[sheet dismissAnimated:YES];
	[sheet autorelease];

	switch(button) {
		case 1:
			[packageManager queuePackage:selectedPackage forOperation:__INSTALL_OPERATION__];
			[packageManager processQueue];
			break;

		case 2:
			if([packageManager queueContainsPackage:selectedPackage]) {
				[packageManager dequeuePackage:selectedPackage];
			} else {
				[packageManager queuePackage:selectedPackage forOperation:__INSTALL_OPERATION__];
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

- (void)_recreateSections
{
	NSString* lastSection = nil;
	NSEnumerator* en = [packages objectEnumerator];
	NSDictionary* package = nil;
	NSRange range = NSMakeRange(0,1);
	int i = 0;
	
	[sections removeAllObjects];
	
	while (package = [en nextObject])
	{
		NSString* firstLetter = [[[package packageName] uppercaseString] substringWithRange:range];
		
		if (![lastSection isEqualToString:firstLetter])
		{
			lastSection = firstLetter;
			[sections addObject:[NSDictionary dictionaryWithObjectsAndKeys:lastSection, @"n", [NSNumber numberWithInt:i], @"i", nil]];
		}
		
		i++;
	}
}

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

	[self _recreateSections];
	[packageSectionList reloadData];
}

@end
