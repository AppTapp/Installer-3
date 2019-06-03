// AppTapp Installer
// Copyright 2007 Nullriver, Inc.

#import "ATSourcesController.h"
#import <UIKit/NSString-UIStringDrawing.h>

extern struct GSFont* UISystemFontForSize(int inSize);


@implementation ATSourcesController

#pragma mark -
#pragma mark Factory

- (id)initInView:(UITransitionView *)aView withTitle:(NSString *)aTitle {
	if((self = [super initInView:aView withTitle:aTitle])) {
		sectionList = [[UISectionList alloc] initWithFrame:[self contentFrame] showSectionIndex:NO];
		[sectionList setDataSource:self];
		[sectionList setAllowsScrollIndicators:YES];

                table = [sectionList table];

		[table setShouldHideHeaderInShortLists:NO];
		[table addTableColumn:[[[UITableColumn alloc] initWithTitle:NSLocalizedString(@"Sources", @"Installer Main") identifier:@"sources" width:320.0f] autorelease]];
		[table setDelegate:self];
		[table setSeparatorStyle:1];
		[table setRowHeight:56.0f];

		packageDataSource = [[ATPackageDataSource alloc] init];

		detailTable = [[UIPreferencesTable alloc] initWithFrame:[self contentFrame]];
		[detailTable setDataSource:self];
		[detailTable setDelegate:self];
		[detailTable setScrollerIndicatorSubrect:CGRectMake(310.0f, 0.0f, 10.0f, 480.0f - 43.0f - 49.0f - 11.0f)];

		addSourceSheet = [[UIAlertSheet alloc] initWithTitle:NSLocalizedString(@"Add Source", @"Sources") buttons:[NSArray arrayWithObjects:NSLocalizedString(@"OK", @""), NSLocalizedString(@"Cancel", @""), nil] defaultButtonIndex:0 delegate:self context:nil];
		addSourceSheetTextField = [addSourceSheet addTextFieldWithValue:@"http://" label:NSLocalizedString(@"Location", @"Sources")];
		[addSourceSheetTextField setAutoCapsType:NO];
		[addSourceSheetTextField setAutoCorrectionType:0];
		[addSourceSheetTextField setPreferredKeyboardType:3];

		editMode = NO;

		[contentView transition:0 toView:sectionList];
	}

	return self;
}

- (void)dealloc {
	[sectionList release];
	[packageDataSource release];
	[detailTable release];
	[addSourceSheet release];

	[super dealloc];
}


#pragma mark -
#pragma mark Methods

- (void)controllerDidBecomeKey {
	[super controllerDidBecomeKey];

	editMode = NO;
	[table enableRowDeletion:editMode];
	[navBar showButtonsWithLeftTitle:NSLocalizedString(@"Refresh", @"Sources") rightTitle:NSLocalizedString(@"Edit", @"Sources")];

	[table setOffset:CGPointMake(0.0f, 0.0f)];
	[sectionList reloadData];
}


#pragma mark -
#pragma mark NavigationBar Delegate

- (void)navigationBar:(id)aNavBar pushedItem:(id)aNavItem {
	int level = [[navBar navigationItems] count];

	if(level == 1) { // Initial push
		[navBar showButtonsWithLeftTitle:NSLocalizedString(@"Refresh", @"Sources") rightTitle:NSLocalizedString(@"Edit", @"Sources")];
		// No transition necessary here
	} else if(level == 2) { // Source Details
		[detailTable reloadData];
		[navBar showButtonsWithLeftTitle:nil rightTitle:nil];
		[contentView transition:1 toView:detailTable];
	} else if(level == 3) {
		UIWebView * infoWebView = [packageDataSource infoWebView];
		UIScroller * infoScroller = [packageDataSource infoScroller];
                
		[infoScroller setFrame:[self contentFrame]];
		[infoWebView setFrame:[self contentFrame]];

		[infoScroller scrollPointVisibleAtTopLeft:CGPointMake(0.0f, 0.0f)];
		[infoWebView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"about:blank"]]];
		[infoWebView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:[selectedSource sourceURL]]]];

		[navBar showButtonsWithLeftTitle:nil rightTitle:nil];
		[contentView transition:1 toView:infoScroller];
	}
}

- (void)navigationBar:(id)aNavBar poppedItem:(id)aNavItem {
	int level = [[navBar navigationItems] count];
	int transition = [navBar isAnimationEnabled] ? 2 : 0;

	if(level == 1) { // Sources List
		[navBar showButtonsWithLeftTitle:NSLocalizedString(@"Refresh", @"Sources") rightTitle:NSLocalizedString(@"Edit", @"Sources")];
		[table selectRow:NSNotFound byExtendingSelection:NO];
		[contentView transition:transition toView:sectionList];
	} else if(level == 2) { // Source Details
		[detailTable selectRow:NSNotFound byExtendingSelection:NO];
		[navBar showButtonsWithLeftTitle:nil rightTitle:nil];
		[contentView transition:transition toView:detailTable];
	}
}

- (void)navigationBar:(id)aNavBar buttonClicked:(int)button {
	int level = [[navBar navigationItems] count];
	if(level == 1) {
		switch(button) {
			case 0:
				if(editMode) {
					[navBar showButtonsWithLeftTitle:NSLocalizedString(@"Refresh", @"Sources") rightTitle:NSLocalizedString(@"Edit", @"Sources")];
					editMode = NO;
				} else {
					[navBar showLeftButton:NSLocalizedString(@"Add", @"Sources") withStyle:0 rightButton:NSLocalizedString(@"Done", @"Sources") withStyle:3];
					editMode = YES;
				}

				[table enableRowDeletion:editMode animated:YES];
				break;

			case 1:
				if(editMode) {
					[addSourceSheetTextField setText:@"http://"];
					[addSourceSheet popupAlertAnimated:YES];
				} else {
					[[ATInstaller sharedInstaller] refresh];
					[sectionList reloadData];
				}
				break;
		}
	}
}


#pragma mark -
#pragma mark UISectionList Delegate

- (int)numberOfSectionsInSectionList:(UISectionList *)aSectionList {
	return [[[packageManager packageSources] sourceCategories] count];
}
                
- (NSString *)sectionList:(UISectionList *)aSectionList titleForSection:(int)row {
	return [[[packageManager packageSources] sourceCategories] objectAtIndex:row];
}
                        
- (int)sectionList:(UISectionList *)aSectionList rowForSection:(int)row {
	NSString * category = [[[packageManager packageSources] sourceCategories] objectAtIndex:row];
	return [[packageManager packageSources] indexOfSourceCategory:category];
}


#pragma mark -
#pragma mark UITable Delegate

- (int)numberOfRowsInTable:(UITable *)aTable {
	if(aTable == table) {
	        return [[packageManager packageSources] count];
	} else {
		return 0;
	}
}
        
- (id)table:(UITable *)aTable cellForRow:(int)row column:(UITableColumn *)aColumn {
	if(aTable == table) {
		ATDetailCell * cell = [[ATDetailCell alloc] init];

		NSDictionary * source = [[packageManager packageSources] objectAtIndex:row];

		UIImage * icon = [UIImage imageNamed:@"Source.png"];
		if([source isTrustedSource]) icon = [UIImage imageNamed:@"SourceTrusted.png"];
		if ([[source sourceLocation] isEqualToString:__LOCAL_SOURCE_LOCATION__]) icon = [UIImage imageNamed:@"SourceLocal.png"];

		[cell setIcon:icon];
		[cell setTitle:[source sourceName]];
		[cell setSubtitle:[source sourceDescription]];

		return [cell autorelease];
	} else {
		return nil;
	}
}

- (BOOL)table:(UITable *)aTable canSelectRow:(int)row {
	if(aTable == table) {
		return YES;
	} else if(aTable == detailTable) {
		return YES;
	} else {
		return NO;
	}
}

- (void)tableSelectionDidChange:(NSNotification *)aNotification {
	UITable * aTable = [aNotification valueForKey:@"object"];
	int row = [aTable selectedRow];
	id cell = [aTable cellAtRow:row column:0];

	if(aTable == table) {
		if(!editMode && [table selectedRow] != NSNotFound && [[table cellAtRow:row column:0] showDisclosure]) {
			selectedSource = [[packageManager packageSources] objectAtIndex:row];
			[navBar pushNavigationItem:[[[UINavigationItem alloc] initWithTitle:NSLocalizedString(@"Source", @"Sources")] autorelease]];
		}
	} else if(aTable == detailTable) {
		if([[cell title] isEqualToString:NSLocalizedString(@"Contact", @"Sources")]) { 
			NSString * subject = [[NSString stringWithFormat:@"Regarding AppTapp source \"%@\"", [selectedSource sourceName]] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
			NSURL * contactURL = [NSURL URLWithString:[NSString stringWithFormat:@"mailto:%@?subject=%@", [selectedSource sourceContact], subject]];
			[detailTable selectRow:NSNotFound byExtendingSelection:NO];
			if(contactURL != nil) [[ATInstaller sharedInstaller] openURL:contactURL];
		} else if([[cell title] isEqualToString:NSLocalizedString(@"More Info", @"Sources")]) {
			[navBar pushNavigationItem:[[[UINavigationItem alloc] initWithTitle:NSLocalizedString(@"More Info", @"Sources")] autorelease]];
		} else if([[cell title] isEqualToString:NSLocalizedString(@"Refresh Now", @"Sources")]) {
			NSLog(@"Refreshing %@", [selectedSource sourceLocation]);
			[aTable selectRow:-1 byExtendingSelection:NO];
			[[NSRunLoop currentRunLoop] runUntilDate:[NSDate date]];
			[[ATInstaller sharedInstaller] refreshOneSource:selectedSource];
		}
	}
}

- (BOOL)table:(UITable *)aTable shouldIndentRow:(int)row {
	if(aTable == table) {
		if(row > 0) return YES;
		else return NO;
	} else {
		return NO;
	}
}

- (BOOL)table:(UITable *)aTable canDeleteRow:(int)row {
	if(aTable == table) {
		if([[NSURL URLWithString:[[[packageManager packageSources] objectAtIndex:row] sourceLocation]] isEqualToURL:[NSURL URLWithString:__DEFAULT_SOURCE_LOCATION__]] || [[[[packageManager packageSources] objectAtIndex:row] sourceLocation] isEqualToString:__LOCAL_SOURCE_LOCATION__]) return NO;
		else return YES;
	} else {
		return NO;
	}
}

- (void)table:(UITable *)aTable deleteRow:(int)row {
	if(aTable == table) {
		NSDictionary * source = [[packageManager packageSources] objectAtIndex:row];
		[packageManager removeSourceWithLocation:[source sourceLocation]];
		[sectionList reloadData];
	}
}

- (void)table:(UITable *)aTable willSwipeToDeleteRow:(int)row {
}

- (BOOL)table:(UITable *)aTable showDisclosureForRow:(int)row {
	if(aTable == table) {
		if([[[[packageManager packageSources] objectAtIndex:row] sourceName] isEqualToString:NSLocalizedString(@"Untitled Source", @"Sources")]) return NO;
		else return YES;
	} else if(aTable == detailTable) {
		if(row == 3 && [selectedSource sourceContact] != nil) {
			return YES;
		} else if(row == 6 && [self preferencesTable:aTable numberOfRowsInGroup:0] == 7) {
			return YES;
		} else {
			return NO;
		}
	} else return NO;
}

- (float)preferencesTable:(UIPreferencesTable *)aTable heightForRow:(int)row inGroup:(int)group withProposedHeight:(float)proposed {
	if(group == 0 && row == 4)
	{
		CGRect textFrame = CGRectMake(20.,10.,280.,570.);
		struct GSFont* font = UISystemFontForSize(18);
		CGSize textSize = [[selectedSource sourceDescription] sizeInRect:textFrame withFont:font];

		return textSize.height + 20;
	}
	else return proposed;

}


#pragma mark -
#pragma mark UIAlertSheet Delegate

- (void)alertSheet:(id)sheet buttonClicked:(int)button {
	if(button == 1) {
		NSString * sourceLocation = [addSourceSheetTextField text];
		[packageManager addSourceWithLocation:sourceLocation];
		[sectionList reloadData];
		
		/* Refresh one source only */
		{
			NSArray* allSources = [packageManager packageSources];
			int i;
			
			for (i=[allSources count]-1;i>=0;i--)
			{
				if ([[[allSources objectAtIndex:i] sourceLocation] isEqualToString:sourceLocation])
				{
					[[ATInstaller sharedInstaller] refreshOneSource:[allSources objectAtIndex:i]];
					break;
				}
			}
		}
	}

	[sheet dismissAnimated:YES];
}


#pragma mark -
#pragma mark UIPreferencesTable Delegate

- (int)numberOfGroupsInPreferencesTable:(UIPreferencesTable *)aTable {
	return 1;
}

- (int)preferencesTable:(UIPreferencesTable *)aTable numberOfRowsInGroup:(int)group {
	if([selectedSource sourceURL] != nil) return 7;
	else return 6;
}

- (id)preferencesTable:(id)preferencesTable titleForGroup:(int)group {
	switch(group) {
		case 0: return NSLocalizedString(@"Source", @"Sources");
	}
}

- (id)preferencesTable:(UIPreferencesTable *)aTable cellForRow:(int)row inGroup:(int)group {
	UIPreferencesTableCell * cell = [[UIPreferencesTableCell alloc] init];

	UITextLabel * label = nil;

	[cell setShowSelection:NO];

	switch(row) {
		case 0:
			[cell setTitle:NSLocalizedString(@"Name", @"Sources")];
			[cell setValue:[selectedSource sourceName]];
			break;

		case 1:
			[cell setTitle:NSLocalizedString(@"Category", @"Sources")];
			[cell setValue:[selectedSource sourceCategory]];
			break;

		case 2:
			[cell setTitle:NSLocalizedString(@"Contact", @"Sources")];
			[cell setValue:[selectedSource sourceMaintainer]];
			if([selectedSource sourceContact] != nil) {
				[cell setShowSelection:YES];
				[cell setShowDisclosure:YES];
			}
			break;

		case 3:
			[cell setTitle:NSLocalizedString(@"Location", @"Sources")];
			[cell setValue:[selectedSource sourceLocation]];
			break;

		case 4:
			{
			CGRect textFrame = CGRectMake(20.,10.,280.,570.);
			struct GSFont* font = UISystemFontForSize(18);
			CGSize textSize = [[selectedSource sourceDescription] sizeInRect:textFrame withFont:font];
			textFrame.size.height = textSize.height;
			label = [[[UITextLabel alloc] initWithFrame:textFrame] autorelease];
			float color[] = { 0.2f, 0.3f, 0.5f, 1.0f };
			CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
			[label setColor:CGColorCreate(colorSpace, color)];
			CGColorSpaceRelease(colorSpace);
			[label setText:[selectedSource sourceDescription]];
			[label setCentersHorizontally:NO];
			[label setWrapsText:YES];
			[cell addSubview:label];
			}
			break;

		case 5:
			if ([selectedSource sourceURL])
			{
				[cell setTitle:NSLocalizedString(@"More Info", @"Sources")];
				[cell setShowSelection:YES];
				[cell setShowDisclosure:YES];
				break;
			}
			// fall through!
			
		case 6:
			{
				[cell setTitle:NSLocalizedString(@"Refresh Now", @"Sources")];
				[cell setShowSelection:YES];
				[cell setAlignment:2];
			}
			break;
	}

	return [cell autorelease];	
}

@end
