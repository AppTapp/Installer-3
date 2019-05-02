// AppTapp Installer
// Copyright 2007 Nullriver, Inc.

#import "ATFeaturedController.h"

#define FEATURED_REFRESH_INTERVAL (1 * 24 * 60 * 60)

@implementation ATFeaturedController

#pragma mark -
#pragma mark Factory

- (id)initInView:(UITransitionView *)aView withTitle:(NSString *)aTitle {
	if((self = [super initInView:aView withTitle:aTitle])) {
		[navBar showButtonsWithLeftTitle:NSLocalizedString(@"Reload", @"Featured Tab") rightTitle:NSLocalizedString(@"About", @"Featured Tab")];

		webView = [[UIWebView alloc] initWithFrame:[self contentFrame]];
		[webView setDelegate:self];
		[webView setAutoresizes:YES];
		[webView setTilingEnabled:YES];
		//[[webView webView] setResourceLoadDelegate:self];

		webScroller = [[UIScroller alloc] initWithFrame:[self contentFrame]];
		[webScroller setBackgroundColor:[[UIImage imageNamed:@"Background.png"] patternColor]];
		[webScroller addSubview:webView];
		
		NSURLRequestCachePolicy cachePolicy = NSURLRequestReturnCacheDataElseLoad;
		
		// check whether last load was > 24 hours ago, if so, force reload (or, rather, gracefully ask to consider it)
		int lastCheckedTimestamp = [preferences integerForKey:@"LastFeaturedRefresh"];
		int now = time(NULL);

		if (!lastCheckedTimestamp || (lastCheckedTimestamp > now))		// force refresh if the date is in the future
			lastCheckedTimestamp = now - FEATURED_REFRESH_INTERVAL - 13;	
		
		if ((now - FEATURED_REFRESH_INTERVAL) > lastCheckedTimestamp)
		{
			[preferences setInteger:now forKey:@"LastFeaturedRefresh"];
			[preferences synchronize];
			
			cachePolicy = NSURLRequestUseProtocolCachePolicy;
		}
		
		[webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:__FEATURED_LOCATION__] cachePolicy:cachePolicy timeoutInterval:30.0f]];

		[contentView transition:0 toView:webScroller];
	}

	return self;
}

- (void)dealloc {
	[webView release];
	[webScroller release];

	[super dealloc];
}


#pragma mark -
#pragma mark UINavigationBar Delegate

- (void)navigationBar:(id)aNavBar buttonClicked:(int)button {
	if(button == 1) {
		[webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:__FEATURED_LOCATION__] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:30.0f]];
	} else {
		UIAlertSheet * aboutAlert = [[UIAlertSheet alloc] init];
		[aboutAlert setTitle:[NSString stringWithFormat:@"Installer v%@", __INSTALLER_VERSION__]];
		[aboutAlert setBodyText:NSLocalizedString(@"Copyright 2007-2019 Nullriver Software, RiP Dev, and the legacy jailbreak community.", @"About Box")];
		[aboutAlert addButtonWithTitle:NSLocalizedString(@"OK", @"")];
		[aboutAlert setDelegate:self];
		[aboutAlert popupAlertAnimated:YES];
	}
}


#pragma mark -
#pragma mark UIAlertSheet Delegate

- (void)alertSheet:(id)sheet buttonClicked:(int)button {
	[sheet dismissAnimated:YES];
}


#pragma mark -
#pragma mark UITable Delegate

- (int)numberOfRowsInTable:(UITable *)aTable {
        return 0;
}
        
- (id)table:(UITable *)aTable cellForRow:(int)row column:(UITableColumn *)aColumn {
	return nil;
}


#pragma mark -
#pragma mark UIWebView Delegate
                
- (void)view:(UIWebView *)aView didDrawInRect:(CGRect)rect duration:(float)duration {
	CGRect frame = [aView frame];
	frame.size.width = 320.0f;
	[webScroller setContentSize:frame.size];
}

- (void)webView:(UIWebView *)sender willClickElement:(id)element {
	if([element respondsToSelector:@selector(absoluteLinkURL)]) {
		NSURL * url = [element absoluteLinkURL];

		if([[url scheme] isEqualToString:@"apptapp"]) {
			NSString * identifier = [url path];
			if(identifier) {
				identifier = [identifier substringFromIndex:1];
				[[ATInstaller sharedInstaller] switchToPackageWithIdentifier:identifier];
			}
		}
	}
}

@end
