#import "AutoInstaller.h"
#import "ATPlatform.h"
#import "common.h"

extern "C" struct CGColor *_UIPinStripeImageColorRef();
extern "C" struct __GSFont* UISystemFontForSize(int inSize);

extern UIApplication* UIApp;

@implementation AutoInstaller

- (void) applicationDidFinishLaunching: (id) unused
{
	CGRect cvRect = [UIHardware fullScreenApplicationContentRect];
	cvRect.origin.x = cvRect.origin.y = 0;

	mWindow = [[UIWindow alloc] initWithContentRect:cvRect];

	mContentView = [[UIView alloc] initWithFrame:cvRect];
	[mWindow setContentView:mContentView];		
	[mContentView setBackgroundColor:_UIPinStripeImageColorRef()];

	float black[4] = {0, 0, 0, 1};
	float grey[4] = {0,0,0, .5};
	float transparent[4] = {0, 0, 0, 0};

	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
	
	CGColorRef transparentColor = CGColorCreate(colorSpace, transparent);
	CGColorRef greyColor = CGColorCreate(colorSpace, grey);
	CGColorRef blackColor = CGColorCreate(colorSpace, black);

	CGColorSpaceRelease(colorSpace);

	CGRect irect = [self centeredRectWithSize:CGSizeMake(200., 22.) origin:CGPointMake(0, 200)];
	mProgressBar = [[UIProgressBar alloc] initWithFrame: irect];
	[mProgressBar setProgress: 0];
	[mProgressBar setStyle: 1];
	[mProgressBar setProgress: 0.];
	[mContentView addSubview: mProgressBar];
	
	mProgressCaption = [[UITextLabel alloc] initWithFrame: [self centeredRectWithSize:CGSizeMake(cvRect.size.width, 25.) origin:CGPointMake(0, 225)]];
	[mProgressCaption setBackgroundColor: transparentColor];
	[mProgressCaption setColor: blackColor];
	[mProgressCaption setCentersHorizontally: YES];
	[mProgressCaption setWrapsText: YES];
	[mProgressCaption setText: NSLocalizedStringWithValue(@"PROGRESS_INITIALIZING", @"Initializing...")];
	[mContentView addSubview: mProgressCaption];
	
	// version caption
	CGRect vcFrame = [self centeredRectWithSize:CGSizeMake(cvRect.size.width, 25.) origin:CGPointMake(0, -5)];
	vcFrame.origin.x = 5;
	
	UITextLabel* vc = [[UITextLabel alloc] initWithFrame:vcFrame ];
	[vc setBackgroundColor: transparentColor];
	[vc setColor: greyColor];
	[vc setFont: UISystemFontForSize(14)];
	[vc setCentersHorizontally: YES];
	[vc setWrapsText: NO];
	[vc setText:NSLocalizedStringWithValue(@"COPYRIGHT", @"Copyright (c) 2008, RiP Dev & Nullriver Software")];
	[mContentView addSubview: vc];
	[vc release];
	
	UIImage* icon = [UIImage applicationImageNamed: @"icon.png"];
	UIImageView *iconView = [[UIImageView alloc] initWithImage: icon];
	[iconView setFrame: [self centeredRectWithSize:CGSizeMake(59, 60) origin:CGPointMake(0, 200-12-64)]];
	[mContentView addSubview: iconView];
	[iconView release];

	icon = [UIImage applicationImageNamed: @"ripdev-small.png"];
	iconView = [[UIImageView alloc] initWithImage: icon];
	CGRect copyrightIconRect = [self centeredRectWithSize:CGSizeMake(24, 24) origin:CGPointMake(0, -5)];
	copyrightIconRect.origin.x = 10;
	[iconView setFrame: copyrightIconRect];
	[mContentView addSubview: iconView];
	[iconView release];

	CGColorRelease(transparentColor);
	CGColorRelease(blackColor);
	CGColorRelease(greyColor);

	[mWindow orderFront: self];
	[[NSRunLoop currentRunLoop] runUntilDate:[NSDate date]];
	
	mPM = [[ATPackageManager sharedPackageManager] retain];
	[mPM setDelegate:self];
	
	[self performSelector:@selector(performAutoinstall:) withObject:self afterDelay:0.1];
}

- (void)performAutoinstall:(id)sender
{
	[mProgressCaption setText:NSLocalizedStringWithValue(@"PROGRESS_SCANNING", @"Scanning packages...")];
	[[NSRunLoop currentRunLoop] runUntilDate:[NSDate date]];

	seteuid(501);
	
	NSMutableArray* packagesToInstall = [self localSourcePackages];
	
	NSLog(@"Packages to install count - %d", [packagesToInstall count]);
	
	if (!packagesToInstall or ![packagesToInstall count])
	{
		[mProgressCaption setText:NSLocalizedStringWithValue(@"PROGRESS_NOTHING_TO_INSTALL", @"Nothing to install.")];
		[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:3.]];

		[UIApp terminateWithSuccess];
		return;
	}
	
	// Otherwise, do the install thing
	NSEnumerator* en = [packagesToInstall objectEnumerator];
	NSMutableDictionary* pack = nil;
	
	seteuid(0);

	
	while (pack = [en nextObject])
	{
		BOOL success = NO;

		mQueueFinished = NO;
		
		NSLog(@"Queueing %@", [pack packageName]);
		
		[mProgressCaption setText:[NSString stringWithFormat:NSLocalizedStringWithValue(@"PROGRESS_INSTALL_FORMAT", @"Queueing %@"), [pack packageName]]];
		[[NSRunLoop currentRunLoop] runUntilDate:[NSDate date]];
		
		[mPM queuePackage:pack forOperation:__INSTALL_OPERATION__];
	}

	NSLog(@"Processing queue...");
	[mPM processQueue];
	
	while(!mQueueFinished) { [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.5]]; };

	NSLog(@"Queue finished.");
	
	seteuid(501);
	
	[mPM saveState];
	
	NSLog(@"All done. Exiting.");
	[mProgressBar setProgress:1.];
	[mProgressCaption setText:NSLocalizedStringWithValue(@"PROGRESS_DONE", @"Done.")];
	[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:3.]];

	[UIApp terminateWithSuccess];
	return;
}

#pragma mark -
#pragma mark •• Misc functions

- (NSMutableDictionary*)localSource
{
	NSEnumerator* sources = [[mPM packageSources] objectEnumerator];
	NSMutableDictionary* src = nil;
	
	while (src = [sources nextObject])
	{
		if ([[src sourceLocation] isEqualToString:__LOCAL_SOURCE_LOCATION__])
			return src;
	}
	
	return nil;
}

- (NSMutableArray*)localSourcePackages
{
	NSEnumerator* allPackages = [[mPM installablePackages] objectEnumerator];
	NSMutableDictionary* pack = nil;
	NSMutableArray* localPackages = [NSMutableArray arrayWithCapacity:0];
	
	while (pack = [allPackages nextObject])
	{
		if ([[pack objectForKey:@"source"] isEqualToString:__LOCAL_SOURCE_LOCATION__])
		{
			// Found a local package!
			if ([[pack objectForKey:@"autoinstall"] boolValue])
			{
				NSLog(@"Adding autoinstall package %@", [pack packageName]);
				[localPackages addObject:pack];
			}
		}
	}
	
	return localPackages;
}

#pragma mark -
#pragma mark •• ATPackageManager Delegate

- (void)packageManager:(id)fp8 startedQueue:(id)fp12
{
	
}

- (void)packageManager:(id)fp8 progressChanged:(id)fp12
{
	[mProgressBar setProgress:[fp12 floatValue]];
}

- (void)packageManager:(id)fp8 statusChanged:(id)fp12
{
	NSLog(@"Progress: %@", fp12);
	[mProgressCaption setText:fp12];
	[[NSRunLoop currentRunLoop] runUntilDate:[NSDate date]];
}

- (void)packageManager:(id)fp8 finishedQueueWithResult:(id)fp12
{
	mQueueFinished = YES;
}

- (void)packageManager:(id)fp8 didAddSource:(id)fp12
{	
}

- (void)packageManager:(id)fp8 didRemoveSource:(id)fp12
{
}

- (void)packageManager:(id)fp8 issuedNotice:(id)fp12
{
	NSLog(@"NOTICE: %@", fp12);
}

- (void)packageManager:(id)fp8 issuedError:(id)fp12
{
	NSLog(@"ERROR: %@", fp12);
}

- (id)packageManagerCanContinue:(id)fp8
{
	return [NSNumber numberWithBool:YES];
}

- (void)packageManager:(id)fp8 confirm:(id)fp12
{
}

- (id)packageManagerConfirmedButton:(id)fp8
{
	return [NSNumber numberWithUnsignedInt:0];
}

#pragma mark -
#pragma mark •• Utility Functions

- (CGRect)centeredRectWithSize:(CGSize)size origin:(CGPoint)origin
{
	CGRect frame = [UIHardware fullScreenApplicationContentRect];
	frame.origin.x = frame.origin.y = 0;

	CGRect n;

	n.origin.x = frame.origin.x + ((frame.size.width / 2) - (size.width / 2));
	if (origin.y < 0)
		n.origin.y = (frame.origin.y + frame.size.height) + origin.y - size.height;
	else
		n.origin.y = frame.origin.y + origin.y;
		
	n.size = size;
	
	return n;
}

@end