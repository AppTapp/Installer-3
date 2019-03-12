// AppTapp Installer
// Copyright 2007 Nullriver, Inc.

#import "ATPackageDataSource.h"
#import <UIKit/NSString-UIStringDrawing.h>


@implementation ATPackageDataSource

static UIWebView * infoWebView = nil;
static UIScroller * infoScroller = nil;

extern struct GSFont* UISystemFontForSize(int inSize);

#pragma mark -
#pragma mark Debug

/*- (BOOL)respondsToSelector:(SEL)aSelector {
	NSLog(@"%@: Request SEL: %@", [self class], NSStringFromSelector(aSelector));
	return [super respondsToSelector:aSelector];
}*/


#pragma mark -
#pragma mark Factory

- (id)init {
	if((self = [super init])) {
		selectedPackage = [[NSMutableDictionary alloc] init];

		if(infoWebView == nil) {
			infoWebView = [[UIWebView alloc] init];
			[infoWebView setDelegate:self];
			[infoWebView setTilingEnabled:YES];
			[infoWebView setAutoresizes:YES];
			//[infoWebView setAllowsUserScaling:YES forDocumentTypes:64];
			//[infoWebView setInitialScale:0.5f forDocumentTypes:32];

			infoScroller = [[UIScroller alloc] init];
			float background[] = { 0.36f, 0.39f, 0.4f, 1.0f };
			CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
			[infoScroller setBackgroundColor:CGColorCreate(colorSpace, background)];
			CGColorSpaceRelease(colorSpace);
			
			[infoScroller setShowBackgroundShadow:YES];
			[infoScroller setAllowsFourWayRubberBanding:YES];
			[infoScroller addSubview:infoWebView];
		}
	}

	return self;
}

- (void)dealloc {
	[selectedPackage release];

	[super dealloc];
}


#pragma mark -
#pragma mark Accessors

- (void)setSelectedPackage:(NSMutableDictionary *)aPackage {
	[aPackage retain];
	[selectedPackage release];
	selectedPackage = aPackage;
}
- (NSMutableDictionary *)selectedPackage {
	return selectedPackage;
}

- (UIWebView *)infoWebView {
	return infoWebView;
}

- (UIScroller *)infoScroller {
	return infoScroller;
}


#pragma mark -
#pragma mark UIPreferencesTable Delegate

- (int)numberOfGroupsInPreferencesTable:(UIPreferencesTable *)aTable {
	if([selectedPackage packageSource] != nil) return 2;
	else return 1;
}

- (int)preferencesTable:(UIPreferencesTable *)aTable numberOfRowsInGroup:(int)group {
	if(group == 0) {
		if([selectedPackage packageURL] != nil) return 6;
		else return 5;
	} else if(group == 1) {
		return 2;
	}
}

- (id)preferencesTable:(id)preferencesTable titleForGroup:(int)group {
	switch(group) {
		case 0: 
			if([selectedPackage packageSponsor]) return [NSString stringWithFormat:NSLocalizedString(@"Package s/b %@", @"Package Info"), [selectedPackage packageSponsor]];
			else return NSLocalizedString(@"Package", @"Package Info");
		case 1: 
			return NSLocalizedString(@"Source", @"Package Info");
	}
}

- (BOOL)preferencesTable:(UIPreferencesTable *)aTable isLabelGroup:(int)group {
	return NO;
}

- (id)preferencesTable:(UIPreferencesTable *)aTable cellForRow:(int)row inGroup:(int)group {
	UIPreferencesTableCell * cell = [[UIPreferencesTableCell alloc] init];

	NSMutableDictionary * source = nil;
	UITextLabel * label = nil;

	[cell setShowSelection:NO];

	switch(group) {
		case 0:
			switch(row) {
				case 0:
					[cell setTitle:NSLocalizedString(@"Name", @"Package Info")];
					[cell setValue:[selectedPackage packageName]];
					break;

				case 1:
					[cell setTitle:NSLocalizedString(@"Version", @"Package Info")];
					[cell setValue:[selectedPackage packageVersion]];
					break;

				case 2:
					[cell setTitle:NSLocalizedString(@"Size", @"Package Info")];
					[cell setValue:[[NSNumber numberWithDouble:[[selectedPackage packageSize] doubleValue]] byteSizeDescription]];
					break;

				case 3:
					[cell setTitle:NSLocalizedString(@"Contact", @"Package Info")];
					[cell setValue:[selectedPackage packageMaintainer]];
					if([selectedPackage packageContact] != nil) {
						[cell setShowSelection:YES];
						[cell setShowDisclosure:YES];
					}					
					break;

				case 4:
					{
						float color[] = { 0.2f, 0.3f, 0.5f, 1.0f };
						CGRect textFrame = CGRectMake(20.,10.,280.,570.);
						struct GSFont* font = UISystemFontForSize(18);
						CGSize textSize = [[selectedPackage packageDescription] sizeInRect:textFrame withFont:font];
						textFrame.size.height = textSize.height;
						label = [[[UITextLabel alloc] initWithFrame:textFrame] autorelease];
						CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
						[label setColor:CGColorCreate(colorSpace, color)];
						CGColorSpaceRelease(colorSpace);
						[label setFont:font];
						[label setText:[selectedPackage packageDescription]];
						[label setCentersHorizontally:NO];
						[label setWrapsText:YES];
						[cell addSubview:label];
					}
					break;

				case 5:
					[cell setTitle:NSLocalizedString(@"More Info", @"Package Info")];
					[cell setShowSelection:YES];
					[cell setShowDisclosure:YES];
					break;
			}
			break;
		case 1:
			source = [selectedPackage packageSource];

			switch(row) {
				case 0:
					[cell setTitle:NSLocalizedString(@"Name", @"Package Info")];
					[cell setValue:[source sourceName]];
					break;

				case 1:
					[cell setTitle:NSLocalizedString(@"Contact", @"Package Info")];
					[cell setValue:[source sourceMaintainer]];
					if([selectedPackage sourceContact] != nil) {
						[cell setShowSelection:YES];
						[cell setShowDisclosure:YES];
					}					
					break;
			}
			break;
	}

	return [cell autorelease];
}

- (float)preferencesTable:(UIPreferencesTable *)aTable heightForRow:(int)row inGroup:(int)group withProposedHeight:(float)proposed {
	if(group == 0 && row == 4)
	{
		CGRect textFrame = CGRectMake(20.,10.,280.,570.);
		struct GSFont* font = UISystemFontForSize(18);
		CGSize textSize = [[selectedPackage packageDescription] sizeInRect:textFrame withFont:font];

		return textSize.height + 20;
	}
	else return proposed;
}


#pragma mark -
#pragma mark UIWebView Delegate

- (void)view:(UIWebView *)aView didDrawInRect:(CGRect)rect duration:(float)duration {
	CGRect frame = [aView frame];
	[infoScroller setContentSize:frame.size];
}

@end
