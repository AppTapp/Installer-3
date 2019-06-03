// AppTapp Installer
// Copyright 2007 Nullriver, Inc.

#import "ATController.h"


@implementation ATController

#pragma mark -
#pragma mark Debug

/*- (BOOL)respondsToSelector:(SEL)aSelector {
	NSLog(@"%@: Request SEL: %@", [self class], NSStringFromSelector(aSelector));
	return [super respondsToSelector:aSelector];
}*/


#pragma mark -
#pragma mark Factory

- (id)initInView:(UITransitionView *)aView withTitle:(NSString *)aTitle {
	if((self = [super init])) {
		packageManager = [[ATPackageManager sharedPackageManager] retain];

		view = [[UIView alloc] initWithFrame:[aView frame]];
		navBar = [[UINavigationBar alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 320.0f, 43.0f)];
		[navBar setDelegate:self];
		[view addSubview:navBar];

		contentView = [[UITransitionView alloc] initWithFrame:[self viewFrame]];
		[view addSubview:contentView];

                UINavigationItem * title = [[[UINavigationItem alloc] initWithTitle:aTitle] autorelease];
                [navBar pushNavigationItem:title];
	}

	return self;
}

- (void)dealloc {
	[packageManager release];
	[view release];
	[navBar release];
	[contentView release];

	[super dealloc];
}


#pragma mark -
#pragma mark Accessors

- (UIView *)view {
	return view;
}

- (UINavigationBar *)navBar {
	return navBar;
}

- (UIView *)contentView {
	return view;
}

- (CGRect)viewFrame {
	CGRect frame = [view frame];
	frame.origin.y = 43.0f;
	frame.size.height -= frame.origin.y;

	return frame;
}

- (CGRect)contentFrame {
	CGRect frame = [contentView frame];
	frame.origin.y = 0.0f;

	return frame;
}


#pragma mark -
#pragma mark Methods

- (void)controllerDidBecomeKey {
	[navBar enableAnimation];
	[self popNavigationBarItems];
}

- (void)controllerDidLoseKey {
	[navBar disableAnimation];
	[self popNavigationBarItems];
}

- (void)popNavigationBarItems {
        if([[navBar navigationItems] count] > 1) {
                [navBar popNavigationItem];
                if([navBar isAnimationEnabled]) [self performSelector:@selector(popNavigationBarItems) withObject:nil afterDelay:0.5f];
                else [self popNavigationBarItems];
        }
}

- (void)packageManagerFinishedQueueWithResult:(NSString *)aResult {
	if([aResult isEqualToString:__SUCCESS__]) {
		[self controllerDidBecomeKey];
	}
}


#pragma mark -
#pragma mark NavigationBar Delegate

- (void)navigationBar:(id)aNavBar pushedItem:(id)aNavItem {
}

- (void)navigationBar:(id)aNavBar poppedItem:(id)aNavItem {
}

@end
