// AppTapp Framework
// Copyright 2007 Nullriver, Inc.

#import <notify.h>
#import "ATPackageManager.h"
#import "ATSourceFetcher.h"

#define	kSourcesInBatch		3

UInt32 _CFVersionNumberFromString(CFStringRef versStr);

@implementation ATPackageManager

static ATPackageManager * sharedInstance = nil;

#pragma mark -
#pragma mark Factory

+ (id)sharedPackageManager {
	if(sharedInstance == nil) sharedInstance = [[self alloc] init];

	return sharedInstance;
}

- (id)init {
	if((self = [super init])) {
		NSLog(@"ATPackageManager: Initializing...");

		upgradeWasPerformed = NO;

		// Create our private directory, if it doesn't exist yet
		if(![[NSFileManager defaultManager] fileExistsAtPath:__PRIVATE_PATH__]) {
			[[NSFileManager defaultManager] createDirectoryAtPath:__PRIVATE_PATH__ attributes:nil];
		}
        
        // Create our temp directory, if it doesn't exist yet
		if(![[NSFileManager defaultManager] fileExistsAtPath:__PARENT_TEMP_PATH__]) {
			[[NSFileManager defaultManager] createDirectoryAtPath:__PARENT_TEMP_PATH__ attributes:nil];
		}

		// Clean up temp files
		if([[NSFileManager defaultManager] fileExistsAtPath:__TEMP_PATH__]) [[NSFileManager defaultManager] removeFileAtPath:__TEMP_PATH__ handler:nil];
		[[NSFileManager defaultManager] createDirectoryAtPath:__TEMP_PATH__ attributes:nil];

		// Register the trusted sources
                if(!(trustedSources = [NSMutableArray arrayWithContentsOfFile:__TRUSTED_SOURCES__])) {
                        trustedSources = [[NSMutableArray alloc] init];
                        [trustedSources addObject:__DEFAULT_SOURCE_LOCATION__];
                }

                // Register the package sources
                if(!(packageSources = [[NSMutableArray alloc] initWithContentsOfFile:__PACKAGE_SOURCES__])) packageSources = [[NSMutableArray alloc] init];
                if([packageSources count] < 1) {
					NSLog(@"No sources found, adding default source.");

					NSMutableDictionary * defaultSource = [NSMutableDictionary dictionaryWithObjectsAndKeys:
										__DEFAULT_SOURCE_NAME__,		@"name",
										__DEFAULT_SOURCE_LOCATION__,		@"location",
										__DEFAULT_SOURCE_MAINTAINER__,		@"maintainer",
										__DEFAULT_SOURCE_CONTACT__,		@"contact",
										__DEFAULT_SOURCE_CATEGORY__,		@"category",
									nil];

					[packageSources addObject:defaultSource];
   				}

				// Check and add the local source
				{
					BOOL localSourceFound = NO;
					NSEnumerator* en = [packageSources objectEnumerator];
					NSMutableDictionary* src = nil;
					
					while (src = [en nextObject])
					{
						if ([[src sourceLocation] isEqualToString:__LOCAL_SOURCE_LOCATION__])
						{
							localSourceFound = YES;
							break;
						}
					}
					
					if (!localSourceFound)
					{
						// create and append local source
						NSMutableDictionary * localSource = [NSMutableDictionary dictionaryWithObjectsAndKeys:
											__LOCAL_SOURCE_NAME__,			@"name",
											__LOCAL_SOURCE_LOCATION__,		@"location",
											__LOCAL_SOURCE_MAINTAINER__,	@"maintainer",
											__LOCAL_SOURCE_CONTACT__,		@"contact",
											__LOCAL_SOURCE_CATEGORY__,		@"category",
											__LOCAL_SOURCE_DESCRIPTION__,	@"description",
										nil];

						[packageSources insertObject:localSource atIndex:1]; 	// inserting at index 1 may sound dangerous at first,
																				// but in fact, since the array always contains
																				// at least 1 source, it should be alright.
					}
				}

		// Register the local packages
		localPackages = nil;

		// Register the remote packages
		remotePackages = nil;

		// These are only stored in memory
		installablePackages = [[NSMutableArray alloc] init];
		updateablePackages = [[NSMutableArray alloc] init];
		uninstallablePackages = [[NSMutableArray alloc] init];
		packageQueue = [[NSMutableArray alloc] init];
		queueOnHold = NO;
		springBoardNeedsRestart = NO;
		sourcesModified = NO;

		script = [[ATScript alloc] init];
		[script setDelegate:self];

		// Resort
		// SKA 03/14/08 Removed the resort to only invoke it on demand - otherwise ATPackageManager starts up too slow
		//[self resort];
		initialSortDone = NO;
	}

	return self;
}

- (void)dealloc {
	[trustedSources release];
	[packageSources release];
	[localPackages release];
	[remotePackages release];
	[installablePackages release];
	[updateablePackages release];
	[uninstallablePackages release];
	[packageQueue release];
	[script release];
	[sourceRefreshQueue release];

	[super dealloc];
}

#pragma mark -
#pragma mark Accessors

- (NSMutableArray *)trustedSources {
	if (!initialSortDone)
	{
		initialSortDone = YES;
		[self resort];
	}
	return trustedSources;
}

- (NSMutableArray *)packageSources {
	if (!initialSortDone)
	{
		initialSortDone = YES;
		[self resort];
	}
	
	return packageSources;
}

- (NSMutableArray *)localPackages {
	if(localPackages == nil) {
		if(!(localPackages = [[NSMutableArray alloc] initWithContentsOfFile:__LOCAL_PACKAGES__])) localPackages = [[NSMutableArray alloc] initWithObjects:[self ownPackage], nil];
	}

	return localPackages;
}

- (NSMutableArray *)remotePackages {
	if(remotePackages == nil) {
		if(!(remotePackages = [[NSMutableArray alloc] initWithContentsOfFile:__REMOTE_PACKAGES__])) remotePackages = [[NSMutableArray alloc] init];
	}

	if (!initialSortDone)
	{
		initialSortDone = YES;
		[self resort];
	}

	return remotePackages;
}

- (NSMutableArray *)installablePackages {
	if (!initialSortDone)
	{
		initialSortDone = YES;
		[self resort];
	}

	return installablePackages;
}

- (NSMutableArray *)updateablePackages {
	if (!initialSortDone)
	{
		initialSortDone = YES;
		[self resort];
	}
	return updateablePackages;
}

- (NSMutableArray *)uninstallablePackages {
	return [self localPackages];
}

- (NSMutableArray *)packageQueue {
	return packageQueue;
}

- (BOOL)hasQueuedPackages {
	return [packageQueue count] > 0;
}

- (BOOL)queueContainsPackage:(NSMutableDictionary *)aPackage {
	return [packageQueue containsQueuedPackage:aPackage];
}


#pragma mark -
#pragma mark Methods

- (NSMutableDictionary *)ownPackage {
	return [NSMutableDictionary dictionaryWithObjectsAndKeys:
			__INSTALLER_BUNDLE_IDENTIFIER__,	@"bundleIdentifier",
			__INSTALLER_NAME__,				@"name",
			__INSTALLER_VERSION__,			@"version",
			__INSTALLER_CATEGORY__,			@"category",
			__INSTALLER_SIZE__,				@"size",
			__INSTALLER_CATEGORY__,			@"category",
			__INSTALLER_DESCRIPTION__,		@"description",
			__DEFAULT_SOURCE_LOCATION__,	@"source",
			__DEFAULT_SOURCE_MAINTAINER__,	@"maintainer",
			__DEFAULT_SOURCE_CONTACT__,		@"contact",
	nil];
}

- (void)setDelegate:(id)aDelegate {
	delegate = aDelegate;
}

- (void)statusChanged:(NSString *)status {
	NSLog(@"ATPackageManager: Status: %@", status);
	[delegate performSelector:@selector(packageManager:statusChanged:) withObject:self withObject:status];
}

- (void)progressChanged:(NSNumber *)progress {
//	NSLog(@"ATPackageManager: Progress %@", progress);
	[delegate performSelector:@selector(packageManager:progressChanged:) withObject:self withObject:progress];
}

- (BOOL)performUpgrade {
	// Check if we need to perform a 2.x -> 3.x upgrade
	NSMutableDictionary * oldInstaller = [[self localPackages] packageWithBundleIdentifier:@"com.nullriver.iphone.Installer"];
	if(oldInstaller != nil) {
		NSLog(@"ATPackageManager: Performing Installer 2.x -> 3.x upgrade...");
		[[self localPackages] removeObject:oldInstaller];

		NSMutableDictionary * ownPackage = [self ownPackage];
		if(![[self localPackages] containsPackage:ownPackage]) [[self localPackages] addObject:ownPackage];
	}
 
	// Upgrade main source
	if([self removeSourceWithLocation:@"http://iphone.nullriver.com/"]) {
		NSLog(@"ATPackageManager: Performing repository upgrade...");
		[self addSourceWithLocation:@"http://repository.apptapp.com/"];
		upgradeWasPerformed = YES;
	}

	// Upgrade community sources identifier
	NSMutableDictionary * oldCS = [[self localPackages] packageWithBundleIdentifier:@"com.nullriver.iphone.community"];
	if(oldCS != nil) {
		NSLog(@"ATPackageManager: Performing Community Sources identifier upgrade...");
		[oldCS setValue:@"com.apptapp.CommunitySources" forKey:@"bundleIdentifier"];
		upgradeWasPerformed = YES;
	}

	// Clean up old files
	NSString * oldPath = @"/var/root/Library/Installer/UpdatedPackages.plist";
	if([[NSFileManager defaultManager] fileExistsAtPath:oldPath]) {
		[[NSFileManager defaultManager] removeFileAtPath:oldPath handler:nil];
	}
	oldPath = @"/var/root/Library/Installer/Preferences.plist";
	if([[NSFileManager defaultManager] fileExistsAtPath:oldPath]) {
		[[NSFileManager defaultManager] removeFileAtPath:oldPath handler:nil];
	}
}

- (BOOL)refreshIsNeeded {
	NSDate * lastRefreshDate = [preferences objectForKey:@"lastRefreshDate"];

	if(lastRefreshDate == nil || upgradeWasPerformed) {
		return YES;
	}

	NSDate * nextRefreshDate = [NSDate dateWithTimeIntervalSince1970:[lastRefreshDate timeIntervalSince1970] + __REFRESH_INTERVAL__];
	NSDate * currentDate = [NSDate date];

	if(
		[[self remotePackages] count] == 0 ||
		[nextRefreshDate laterDate:currentDate] == currentDate ||
		[lastRefreshDate laterDate:currentDate] == lastRefreshDate
	) {
		return YES;
	} else {
		return NO;
	}
}

- (void)resort {
	// Sort the sources by category, alpha
	[packageSources sortUsingSelector:@selector(caseInsensitiveCompareSourceCategory:)];

	// Sort remote packages by category, alpha
	[[self remotePackages] sortUsingSelector:@selector(caseInsensitiveComparePackageCategory:)];

	// Sort through the remote packages, adding them into the appropriate index arrays
	[installablePackages removeAllObjects];
	[updateablePackages removeAllObjects];

	NSEnumerator * allPackages = [[self remotePackages] objectEnumerator];
	NSMutableDictionary * package;

	while((package = [allPackages nextObject])) {
		NSMutableDictionary * oldPackage;
		if((oldPackage = [[self localPackages] packageWithBundleIdentifier:[package packageBundleIdentifier]])) {
			if ([self localVersionIsOlder:[oldPackage packageVersion] comparedToRemoteVersion:[package packageVersion]]) {
			//if(![[oldPackage packageVersion] isEqualToString:[package packageVersion]]) {
				[updateablePackages addObject:package];
			} else {
				// Do nothing with packages already installed
			}
		} else {
			[installablePackages addObject:package];
		}
	}

	[updateablePackages sortUsingSelector:@selector(comparePackageDate:)];
}

- (BOOL)localVersionIsOlder:(NSString*)localVersion comparedToRemoteVersion:(NSString*)remoteVersion
{
	// Try to normalize using Apple's built-in normalizer. It fails on versions such as 3.11 though, but
	// works fairly well on 1.2.3b4 - so if we can normalize both version numbers, use that, otherwise, use
	// either ours (commented out for now) or the old-fashioned isEqualToString.
	{
		int local = _CFVersionNumberFromString((CFStringRef)localVersion);
		int remote = _CFVersionNumberFromString((CFStringRef)remoteVersion);
		
		if (local && remote)
		{
			return (local < remote);
		}
		
		// otherwise, fall back to our normalizer
	}
	
	return (![localVersion isEqualToString:remoteVersion]);
	
	// SKA Normalize version is commented out for now, as it has issues with comparing things like 1.0b5 vs 1.0fc1,
	// so we'll just use the old-skool isEqualToString if _CFVersionNumberFromString fails.
	
	/*
	NSString* local = [self _normalizeVersion:localVersion];
	NSString* remote = [self _normalizeVersion:remoteVersion];
	
	if (![local length] || ![remote length])	// cannot normalize version, use "old skool" comparison method
	{
		return (![localVersion isEqualToString:remoteVersion]);
	}

	return ([local compare:remote options:0] == NSOrderedAscending);
	*/
}

- (NSString*)_normalizeVersion:(NSString*)version
{
	NSMutableString* result = [NSMutableString stringWithCapacity:5];
	int i;
	int len = [version length];
	
	for (i=0; i < len; i++)
	{
		unichar c = [version characterAtIndex:i];
		if (c >= (unichar)'0' && c <= (unichar)'9')
		{
			[result appendString:[NSString stringWithCharacters:&c length:1]];
			if ([result length] >= 5)
				break;
		}
	}
	
	if ([result length] < 5)
	{
		for (i=5-[result length]; i>0; i--)
		{
			unichar zero = (unichar)(i > 2 ? '0' : 'a');
			[result appendString:[NSString stringWithCharacters:&zero length:1]];
		}
	}
		
	return result;
}

- (void)saveState {
	NSLog(@"ATPackageManager: Saving state...");
	
	/* SKA 03/14/08 Converted the saving of the plists to the binary format: takes less space, loads up faster. */
	NSData* data = nil;
	
	NSAutoreleasePool* pool;
	
	pool = [[NSAutoreleasePool alloc] init];
	NSLog(@"ATPackageManager: Saving state: local packages...");
	data = [NSPropertyListSerialization dataFromPropertyList:[self localPackages] format:NSPropertyListBinaryFormat_v1_0 errorDescription:NULL];
	if (data)
		[data writeToFile:__LOCAL_PACKAGES__ atomically:YES];
	[pool release];
	
	pool = [[NSAutoreleasePool alloc] init];
	NSLog(@"ATPackageManager: Saving state: package sources...");
	data = [NSPropertyListSerialization dataFromPropertyList:[self packageSources] format:NSPropertyListBinaryFormat_v1_0 errorDescription:NULL];
	if (data)
		[data writeToFile:__PACKAGE_SOURCES__ atomically:YES];
	[pool release];
	
	pool = [[NSAutoreleasePool alloc] init];
	NSLog(@"ATPackageManager: Saving state: remote packages...");
	data = [NSPropertyListSerialization dataFromPropertyList:[self remotePackages] format:NSPropertyListBinaryFormat_v1_0 errorDescription:NULL];
	if (data)
		[data writeToFile:__REMOTE_PACKAGES__ atomically:YES];
	[pool release];

	pool = [[NSAutoreleasePool alloc] init];
	NSLog(@"ATPackageManager: Saving state: trusted sources...");
	data = [NSPropertyListSerialization dataFromPropertyList:[self trustedSources] format:NSPropertyListBinaryFormat_v1_0 errorDescription:NULL];
	if (data)
		[data writeToFile:__TRUSTED_SOURCES__ atomically:YES];
	[pool release];
	/* ~SKA */

	[preferences synchronize];
}

- (BOOL)addSourceWithLocation:(NSString *)sourceLocation {
	if(![packageSources containsSourceWithLocation:sourceLocation]) {
		NSMutableDictionary * source = [NSMutableDictionary dictionaryWithObjectsAndKeys:
							sourceLocation, @"location",
							@"Untitled Source", @"name",
						nil];

		[packageSources addObject:source];
		[self saveState];

		[delegate performSelector:@selector(packageManager:didAddSource:) withObject:self withObject:source];

		return YES;
	} else {
		return NO;
	}
}

- (BOOL)removeSourceWithLocation:(NSString *)sourceLocation {
	NSMutableDictionary * source = [packageSources sourceWithLocation:sourceLocation];

	if(source != nil) {
		[self removeStalePackagesForSource:source];
		[packageSources removeObject:source];

		[self resort];
		[self saveState];

		[delegate performSelector:@selector(packageManager:didRemoveSource:) withObject:self withObject:source];

		return YES;
	} else {
		return NO;
	}
}

- (BOOL)refreshTrustedSources {
	[self statusChanged:@"Checking sources..."];
	[self progressChanged:[NSNumber numberWithInt:0]];

	NSArray * newTrustedSources = [NSArray arrayWithContentsOfURL:[NSURL URLWithString:__TRUSTED_SOURCES_LOCATION__]];

	NSLog(@"ATPackageManager: newTrustedSources = %@", newTrustedSources);
	
	if(newTrustedSources != nil && [newTrustedSources count] > 0) {
		[trustedSources removeAllObjects];
		[trustedSources addObjectsFromArray:newTrustedSources];

		return YES;

	} else {
		return NO;
	}
}

- (BOOL)refreshAllSources {
	[self statusChanged:@"Refreshing sources..."];
	[self progressChanged:[NSNumber numberWithInt:0]];

	BOOL atLeastOneSource = NO;
	int percent = 0;
	int count = 0;
	
	sourcesRefreshed = 0;

	NSEnumerator		*	allSources = [packageSources reverseObjectEnumerator];
	NSDictionary	*	source;
	
	// Create a chain of source fetchers
	if (sourceRefreshQueue)
		[sourceRefreshQueue release];
	
	sourceRefreshQueue = [[NSMutableDictionary dictionaryWithCapacity:0] retain];

	[self progressChanged:[NSNumber numberWithInt:0]];
	
	int a = 0;
	while((source = [allSources nextObject])) {
		if ([[source sourceLocation] isEqualToString:__LOCAL_SOURCE_LOCATION__])
		{
			// this is a special case for the local source
			[self scanLocalSource:source];
			double percent = (double)++sourcesRefreshed / ([packageSources count] / 100.);
			[self progressChanged:[NSNumber numberWithInt:percent]];
			
			continue;
		}
		
		// queue it up!
		ATSourceFetcher* sf = [ATSourceFetcher refreshSource:source notifying:self];
		[sourceRefreshQueue setObject:sf forKey:source];
		
		[sf start];
		
		a++;
		
		if ((a%kSourcesInBatch) == 0)
		{
			NSLog(@"ATPackageManager: Waiting on this batch... [%d in %d]", a, [sourceRefreshQueue count]);
			NSTimeInterval ti = [[NSDate date] timeIntervalSinceReferenceDate];
			while ([sourceRefreshQueue count] >= kSourcesInBatch)
			{			
				[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1.]];

				if ([[NSDate date] timeIntervalSinceReferenceDate] - ti > 10.)
				{
					NSLog(@"ATPackageManager: Killed the batch wait...");
					break;
				}
			}
			NSLog(@"ATPackageManager: Leaving the waiting on this batch... [%d in %d]", a, [sourceRefreshQueue count]);
			
			a = [sourceRefreshQueue count];
		}
	}
	
	NSLog(@"ATPackageManager: Waiting on remainder batch (%d)...", [sourceRefreshQueue count]);
	NSTimeInterval ti = [[NSDate date] timeIntervalSinceReferenceDate];
	while ([sourceRefreshQueue count] > 0)
	{
		[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:2.]];
		
		if ([[NSDate date] timeIntervalSinceReferenceDate] - ti > 60.)
		{
			NSLog(@"ATPackageManager: Killed the remainder batch wait...");
			break;
		}
	}
	
	[preferences setObject:[NSDate date] forKey:@"lastRefreshDate"];
	[self resort];
	[self saveState];

	return YES;
}

- (void)sourceRefreshDidComplete:(NSDictionary*)source index:(NSDictionary*)sourceIndex
{
	NSLog(@"ATPackageManager: Source refresh: success for %@", [source sourceLocation]);
	
	sourcesRefreshed++;
	
	// Do the mmm-bop
	if(sourceIndex != nil) {
		// Gather and update source information
		NSDictionary * sourceInfo = [sourceIndex valueForKey:@"info"];
		if(sourceInfo != nil) [source updateSourceFromInfo:sourceInfo];

		// Remove stale packages
		[self removeStalePackagesForSource:(NSMutableDictionary*)source];

		// Gather and update packages
		NSArray 		* sourcePackages = [[[sourceIndex valueForKey:@"packages"] mutableCopy] autorelease];
		NSEnumerator		* allSourcePackages = [sourcePackages objectEnumerator];
		NSMutableDictionary	* sourcePackage;

		while((sourcePackage = [allSourcePackages nextObject])) {
			[sourcePackage setValue:[source sourceLocation] forKey:@"source"];
			if([sourcePackage packageMaintainer] == nil && [source sourceMaintainer] != nil) [sourcePackage setValue:[source sourceMaintainer] forKey:@"maintainer"];
			if([sourcePackage packageContact] == nil && [source sourceContact] != nil) [sourcePackage setValue:[source sourceContact] forKey:@"contact"];
			if([sourcePackage packageSponsor] == nil && [source sourceSponsor] != nil) [sourcePackage setValue:[source sourceSponsor] forKey:@"sponsor"];

			if([sourcePackage isValidPackage]) {
				[[self remotePackages] addObject:sourcePackage];
			} else {
				NSLog(@"ATPackageManager: Invalid package: %@", sourcePackage);
			}
		}
	}
	
	// Update progress
	[sourceRefreshQueue removeObjectForKey:source];
	
/*	NSLog(@"Sources remaining to be refreshed: ");
	int z;
	NSArray* keys = [sourceRefreshQueue allKeys];
	for (z=0;z<[keys count];z++)
	{
		NSLog(@" - %@", [[keys objectAtIndex:z] sourceLocation]);
	}
*/
	double percent = (double)sourcesRefreshed / ([packageSources count] / 100.);
	[self progressChanged:[NSNumber numberWithInt:percent]];
}

- (void)sourceRefreshDidFail:(NSDictionary*)source withError:(NSError*)error
{
	NSLog(@"ATPackageManager: Source refresh: error %@ for %@", error, [source sourceLocation]);
	[sourceRefreshQueue removeObjectForKey:source];
	
	sourcesRefreshed++;
	
	// Update progress
	double percent = (double)sourcesRefreshed / ([packageSources count] / 100.);
	[self progressChanged:[NSNumber numberWithInt:percent]];
}


- (BOOL)refreshSource:(NSMutableDictionary *)aSource {
	NSLog(@"ATPackageManager: Refreshing source: %@", [aSource sourceLocation]);

	[self statusChanged:@"Refreshing sources..."];
	[self progressChanged:[NSNumber numberWithInt:50]];
	
	if ([[aSource sourceLocation] isEqualToString:__LOCAL_SOURCE_LOCATION__])
	{
		// this is a special case for the local source
		[self scanLocalSource:aSource];
		[self progressChanged:[NSNumber numberWithInt:100]];
		[self resort];
		[self saveState];
		
		return YES;
	}

	NSURL * sourceURL = [NSURL URLWithString:[aSource sourceLocation]];	
	NSDictionary * sourceIndex = [NSDictionary dictionaryWithContentsOfURL:sourceURL];

	if(sourceIndex != nil) {
		// Gather and update source information
		NSDictionary * sourceInfo = [sourceIndex valueForKey:@"info"];
		if(sourceInfo != nil) [aSource updateSourceFromInfo:sourceInfo];

		// Remove stale packages
		[self removeStalePackagesForSource:aSource];

		// Gather and update packages
		NSArray 		* sourcePackages = [[[sourceIndex valueForKey:@"packages"] mutableCopy] autorelease];
		NSEnumerator		* allSourcePackages = [sourcePackages objectEnumerator];
		NSMutableDictionary	* sourcePackage;

		while((sourcePackage = [allSourcePackages nextObject])) {
			[sourcePackage setValue:[aSource sourceLocation] forKey:@"source"];
			if([sourcePackage packageMaintainer] == nil && [aSource sourceMaintainer] != nil) [sourcePackage setValue:[aSource sourceMaintainer] forKey:@"maintainer"];
			if([sourcePackage packageContact] == nil && [aSource sourceContact] != nil) [sourcePackage setValue:[aSource sourceContact] forKey:@"contact"];
			if([sourcePackage packageSponsor] == nil && [aSource sourceSponsor] != nil) [sourcePackage setValue:[aSource sourceSponsor] forKey:@"sponsor"];

			if([sourcePackage isValidPackage]) {
				[[self remotePackages] addObject:sourcePackage];
			} else {
				NSLog(@"ATPackageManager: Invalid package: %@", sourcePackage);
			}
		}
		
		[self progressChanged:[NSNumber numberWithInt:100]];
		[self resort];
		[self saveState];

		return YES;
	} else {
		NSLog(@"ATPackageManager: Could not refresh source: %@", [aSource sourceLocation]);

		[self progressChanged:[NSNumber numberWithInt:100]];
		
		return NO;
	}
}

- (BOOL)removeStalePackagesForSource:(NSMutableDictionary *)aSource {
	NSMutableArray	* freshSourceLocations = [NSMutableArray array];

	NSEnumerator	* allSources = [packageSources objectEnumerator];
	NSString	* sourceLocation;

	// Find all the non-stale (fresh) sources
	while((sourceLocation = [[allSources nextObject] sourceLocation])) {
		if(![sourceLocation isEqualToString:[aSource sourceLocation]]) [freshSourceLocations addObject:sourceLocation];
	}

	// Now we wipe out all stale packages
	NSEnumerator * allPackages = [[[[self remotePackages] copy] autorelease] objectEnumerator];
	NSMutableDictionary * package;

	while((package = [allPackages nextObject])) {
		if(![freshSourceLocations containsObject:[package packageSourceLocation]]) {
			[[self remotePackages] removeObject:package];
		}
	}
}

- (BOOL)clearQueue {
	if([packageQueue count]) {
		NSLog(@"ATPackageManager: Package queue was cleared.");;
		[packageQueue removeAllObjects];
		return YES;
	} else {
		return NO;
	}
}

- (BOOL)dequeuePackage:(NSMutableDictionary *)aPackage {
	NSEnumerator * allQueuedOperations = [[[packageQueue copy] autorelease] objectEnumerator];
	NSDictionary * queuedPackage;
	unsigned int index = 0;

	while(queuedPackage = [[allQueuedOperations nextObject] queuedPackage]) {
		if([[queuedPackage packageBundleIdentifier] isEqualToString:[aPackage packageBundleIdentifier]]) {
			NSLog(@"ATPackageManager: Removed package \"%@\" from queue.", [aPackage packageName]);
			[packageQueue removeObjectAtIndex:index];
		}

		index++;
	}

	return NO;
}

- (BOOL)queuePackage:(NSMutableDictionary *)aPackage forOperation:(NSString *)anOperation {
	NSLog(@"ATPackageManager: Queued package \"%@\" for operation \"%@\".", [aPackage packageName], anOperation);

	NSDictionary * packageOperation = [NSDictionary dictionaryWithObjectsAndKeys:
							aPackage, @"package",
							anOperation, @"operation",
						nil];

	if(![packageQueue containsObject:packageOperation]) [packageQueue addObject:packageOperation];
}

- (BOOL)processQueue {
	if([packageQueue count] == 0) return NO;

	[delegate performSelector:@selector(packageManager:startedQueue:) withObject:self withObject:packageQueue];

	NSEnumerator * allQueuedPackages = [[[packageQueue copy] autorelease] objectEnumerator];
	NSDictionary * packageOperation;

	queueOnHold = NO;
	BOOL queueFailed = NO;

	while((packageOperation = [allQueuedPackages nextObject])) {
		NSMutableDictionary * package = [packageOperation queuedPackage];
		NSString * operation = [packageOperation queuedOperation];

		if([self performOperation:operation onPackage:package]) {
			[packageQueue removeObject:packageOperation];
		} else if(queueOnHold) { // Queue hold
			NSLog(@"ATPackageManager: Queue was put on hold.");
			break;
		} else {
			// Remove the failed package from the queue
			NSLog(@"ATPackageManager: Removing failed package from queue!");
			[packageQueue removeObject:packageOperation];
			queueFailed = YES;
			break;
		}
	}

	if(!queueOnHold && !queueFailed) { // Operation completed
		if(sourcesModified) {
			if([self refreshAllSources]) sourcesModified = NO;
		}
		[delegate performSelector:@selector(packageManager:finishedQueueWithResult:) withObject:self withObject:__SUCCESS__];
	} else if(queueFailed) { // Failed
		[delegate performSelector:@selector(packageManager:finishedQueueWithResult:) withObject:self withObject:__FAILURE__];
	}

	return YES;
}

- (BOOL)performOperation:(NSString *)anOperation onPackage:(NSMutableDictionary *)aPackage {
	NSLog(@"ATPackageManager: Perfoming operation \"%@\" on package \"%@\"...", anOperation, [aPackage packageName]);

	// We need to download files for an install or update, but not an uninstall
	if([anOperation isEqualToString:__INSTALL_OPERATION__] || [anOperation isEqualToString:__UPDATE_OPERATION__]) { 
		// Make sure we have at least 1MB free on root fs for Installer updates
		if([[aPackage packageBundleIdentifier] isEqualToString:__INSTALLER_BUNDLE_IDENTIFIER__]) {
			if([[[NSFileManager defaultManager] freeSpaceAtPath:@"/"] unsignedLongLongValue] <  512 * 1024) {
				NSLog(@"ATPackageManager: Failing Installer update, not enough free space on root filesystem!");
				[self scriptError:@"Not enough free space to update Installer! Please free at least 512 KB of space."];
				return NO;
			}
		}

		// Check if we need to download
		if([ATDownloader downloadPackage:aPackage notifying:self]) {
			queueOnHold = YES;
			return NO; // Put queue on hold
		} // Otherwise, we continue
	}

	// Set the target package for scripting
	[script setPackage:aPackage];

	// Run preflight
	if(
		![anOperation isEqualToString:__UNINSTALL_OPERATION__] &&
		[[aPackage packageScriptNamed:@"preflight"] count]
	) {
		[self statusChanged:@"Running preflight..."];
		[script setScriptCommands:[aPackage packageScriptNamed:@"preflight"]];

		if(![script run]) {
			if(![script scriptAbortedGracefully]) [self scriptError:@"Preflight script execution failed!"];
			return NO;
		}
	}

	// Run main script
	if([anOperation isEqualToString:__INSTALL_OPERATION__]) {
		[self statusChanged:@"Installing package..."];
		[script setScriptCommands:[aPackage packageScriptNamed:@"install"]];
	} else if([anOperation isEqualToString:__UPDATE_OPERATION__]) {
		[self statusChanged:@"Updating package..."];
		if([[aPackage packageScriptNamed:@"update"] count]) {
			[script setScriptCommands:[aPackage packageScriptNamed:@"update"]];
		} else {
			[script setScriptCommands:[aPackage packageScriptNamed:@"install"]];
		}
	} else if([anOperation isEqualToString:__UNINSTALL_OPERATION__]) {
		[self statusChanged:@"Uninstalling package..."];
		[script setScriptCommands:[aPackage packageScriptNamed:@"uninstall"]];
	}

	if(![script run]) {
		if(![script scriptAbortedGracefully]) [self scriptError:@"Main script execution failed!"];
		return NO;
	}

	// Run postflight
	if(
		![anOperation isEqualToString:__UNINSTALL_OPERATION__] &&
		[[aPackage packageScriptNamed:@"postflight"] count]
	) {
		[self statusChanged:@"Running postflight..."];
		[script setScriptCommands:[aPackage packageScriptNamed:@"postflight"]];

		if(![script run]) {
			if(![script scriptAbortedGracefully]) [self scriptError:@"Postflight script execution failed!"];
			return NO;
		}
	}

	[self statusChanged:@"Cleaning up..."];
	[[NSFileManager defaultManager] removeFileAtPath:[aPackage packageTempFile] handler:nil];

	// Restart after any successful package operation when SummerBoard isn't installed
	springBoardNeedsRestart = YES;

	// Operation completed, move package entry
	if([anOperation isEqualToString:__INSTALL_OPERATION__]) {
		[[self localPackages] addObject:aPackage];
	} else if([anOperation isEqualToString:__UPDATE_OPERATION__]) {
		NSMutableDictionary * oldPackage = [[self localPackages] packageWithBundleIdentifier:[aPackage packageBundleIdentifier]];
		[[self localPackages] removeObject:oldPackage];
		[[self localPackages] addObject:aPackage];
	} else if([anOperation isEqualToString:__UNINSTALL_OPERATION__]) {
		[[self localPackages] removeObject:aPackage];
	}

	NSLog(@"ATPackageManager: Operation on package \"%@\" completed successfully.", [aPackage packageName]);

	[self resort];
	[self saveState];

	return YES;
}


#pragma mark -
#pragma mark ATDownloader Delegate

- (void)packageDownload:(NSMutableDictionary *)aPackage statusChanged:(NSString *)status {
	[self statusChanged:status];
}

- (void)packageDownload:(NSMutableDictionary *)aPackage progressChanged:(NSNumber *)progress {
	[self progressChanged:progress];
}

- (void)packageDownloadCompleted:(NSMutableDictionary *)aPackage {
	if(queueOnHold) [self processQueue];
}

- (void)packageDownload:(NSMutableDictionary *)aPackage failedWithError:(NSString *)error {
	[self scriptError:error];
}

- (void)restartSpringBoardIfNeeded {
	if(springBoardNeedsRestart) {
		
		if ([ATPlatform hasNikita])
		{
			notify_post("com.apple.language.changed");
		}
		else
		{		
			pid_t pid = fork();

			if(pid == 0) {
				execlp("/bin/launchctl", "launchctl", "stop", "com.apple.SpringBoard", (char *)0);
				exit(1);
			} else if(pid < 0) {
				NSLog(@"ATPackageManager: Failed forking process for restart of SpringBoard!");
			}
		}
	}
}


#pragma mark -
#pragma mark ATScript Delegate

- (void)scriptDidChangeProgress:(NSNumber *)progress {
	[self progressChanged:progress];
}

- (void)scriptNotice:(NSString *)aNotice {
	[delegate performSelector:@selector(packageManager:issuedNotice:) withObject:self withObject:aNotice];
}

- (void)scriptError:(NSString *)anError {
	[delegate performSelector:@selector(packageManager:issuedError:) withObject:self withObject:anError];
}

- (NSNumber *)scriptCanContinue {
	return [delegate performSelector:@selector(packageManagerCanContinue:) withObject:self];
}

- (void)scriptConfirm:(NSArray *)arguments {
	[delegate performSelector:@selector(packageManager:confirm:) withObject:self withObject:arguments];
}

- (NSNumber *)scriptConfirmedButton {
	return [delegate performSelector:@selector(packageManagerConfirmedButton:) withObject:self];
}

- (NSNumber *)scriptIsPackageInstalled:(NSString *)bundleIdentifier {
	if([[self localPackages] packageWithBundleIdentifier:bundleIdentifier] != nil) return [NSNumber numberWithBool:YES];
	else return [NSNumber numberWithBool:NO];
}

- (void)scriptAddSource:(NSString *)aSource {
	if([self addSourceWithLocation:aSource]) sourcesModified = YES;
}

- (void)scriptRemoveSource:(NSString *)aSource {
	if([self removeSourceWithLocation:aSource]) sourcesModified = YES;
}

- (void)scriptRestartSpringBoard {
	springBoardNeedsRestart = YES;
}

#pragma mark -
#pragma mark Local source support

- (void)scanLocalSource:(NSMutableDictionary*)localSource
{
	NSMutableArray* lp = [NSMutableArray arrayWithCapacity:0];
	
	NSLog(@"Scanning local source @ %@...", __LOCAL_SOURCE_FOLDER__);
	
	if (![[NSFileManager defaultManager] fileExistsAtPath:__LOCAL_SOURCE_FOLDER__])
	{
		[[NSFileManager defaultManager] createDirectoryAtPath:__LOCAL_SOURCE_FOLDER__ attributes:nil];
		NSLog(@"Created local source folder.");
	}
	
	NSEnumerator* en = [[NSFileManager defaultManager] enumeratorAtPath:__LOCAL_SOURCE_FOLDER__];
	NSString* filename;
	
	while (filename = [en nextObject])
	{
		if ([[filename pathExtension] isEqualToString:@"plist"])
		{
			// Woot, a package description file! Let's try to read it in...
			
			NSMutableDictionary* dict = [NSMutableDictionary dictionaryWithContentsOfFile:[__LOCAL_SOURCE_FOLDER__ stringByAppendingPathComponent:filename]];
			
			if (dict && [dict objectForKey:@"packages"])
			{
				NSArray* pack = [dict objectForKey:@"packages"];
				NSEnumerator* en = [pack objectEnumerator];
				NSMutableDictionary* p;
				
				while (p = [en nextObject])
				{
					// Fix up the location
					NSString* fileName = [p packageLocation];
					
					if ([[NSFileManager defaultManager] fileExistsAtPath:[__LOCAL_SOURCE_FOLDER__ stringByAppendingPathComponent:[p objectForKey:@"location"]]])
					{
						NSURL* fileURL = [NSURL fileURLWithPath:[__LOCAL_SOURCE_FOLDER__ stringByAppendingPathComponent:[p objectForKey:@"location"]]];
						
						[p setObject:[fileURL absoluteString] forKey:@"location"];
						
						[lp addObject:p];
					}
					else
						NSLog(@"ATPackageManager: Local package %@ misses the file (%@), skipping.", [p objectForKey:@"bundleIdentifier"], [p objectForKey:@"location"]);
				}
			}
		}
		else if ([[filename pathExtension] isEqualToString:@"zip"])
		{
			// Woot, a zip file! Let's try to find AppTapp.plist inside and read it in...
			NSLog(@"ATPackageManager: Analyzing %@", filename);
			ATUnpacker* unpack = [[ATUnpacker alloc] initWithPath:[__LOCAL_SOURCE_FOLDER__ stringByAppendingPathComponent:filename]];
			if (unpack)
			{
				char* tempdir = tempnam("/tmp", "Installer_");
				if (!tempdir)
				{
					[unpack release];
					continue;
				}

				NSString * outputFile = [[NSFileManager defaultManager] stringWithFileSystemRepresentation:tempdir length:strlen(tempdir)];
				
				if ([unpack copyCompressedPath:@"AppTapp.plist" toFileSystemPath:outputFile])
				{
					// Woot, the zip file contains AppTapp.plist that we'll use! :)
					NSMutableDictionary* dict = [NSMutableDictionary dictionaryWithContentsOfFile:outputFile];

					if (dict && [dict objectForKey:@"packages"])
					{
						NSArray* pack = [dict objectForKey:@"packages"];
						NSEnumerator* en = [pack objectEnumerator];
						NSMutableDictionary* p;

						while (p = [en nextObject])
						{
							// Fix up the location
							NSURL* fileURL = [NSURL fileURLWithPath:[__LOCAL_SOURCE_FOLDER__ stringByAppendingPathComponent:filename]];

							[p setObject:[fileURL absoluteString] forKey:@"location"];

							[lp addObject:p];
						}
					}
				}
				[unpack release];
			}
		}
	}
	
	en = [lp objectEnumerator];
	NSMutableDictionary* p = nil;
	
	[self removeStalePackagesForSource:localSource];
	
	while (p = [en nextObject])
	{
		[p setValue:[localSource sourceLocation] forKey:@"source"];
		if([p packageMaintainer] == nil && [localSource sourceMaintainer] != nil) [p setValue:[localSource sourceMaintainer] forKey:@"maintainer"];
		if([p packageContact] == nil && [localSource sourceContact] != nil) [p setValue:[localSource sourceContact] forKey:@"contact"];
		if([p packageSponsor] == nil && [localSource sourceSponsor] != nil) [p setValue:[localSource sourceSponsor] forKey:@"sponsor"];

		if([p isValidPackage]) {
			NSLog(@"ATPackageManager: Adding local package: %@", [p packageName]);
			[[self remotePackages] addObject:p];
		} else {
			NSLog(@"ATPackageManager: Invalid package: %@", p);
		}
	}
}

@end

#pragma mark -
#pragma mark Stolen from CF

#define DEVELOPMENT_STAGE 0x20
#define ALPHA_STAGE 0x40
#define BETA_STAGE 0x60
#define RELEASE_STAGE 0x80

#define MAX_VERS_LEN 10

inline Boolean _isDigit(UniChar aChar) {return (((aChar >= (UniChar)'0') && (aChar <= (UniChar)'9')) ? true : false);}

UInt32 _CFVersionNumberFromString(CFStringRef versStr) {
    // Parse version number from string.
    // String can begin with "." for major version number 0.  String can end at any point, but elements within the string cannot be skipped.
    UInt32 major1 = 0, major2 = 0, minor1 = 0, minor2 = 0, stage = RELEASE_STAGE, build = 0;
    UniChar versChars[MAX_VERS_LEN];
    UniChar *chars = NULL;
    CFIndex len;
    UInt32 theVers;
    Boolean digitsDone = false;

    if (!versStr) return 0;

    len = CFStringGetLength(versStr);

    if ((len == 0) || (len > MAX_VERS_LEN)) return 0;

    CFStringGetCharacters(versStr, CFRangeMake(0, len), versChars);
    chars = versChars;
    
    // Get major version number.
    major1 = major2 = 0;
    if (_isDigit(*chars)) {
        major2 = *chars - (UniChar)'0';
        chars++;
        len--;
        if (len > 0) {
            if (_isDigit(*chars)) {
                major1 = major2;
                major2 = *chars - (UniChar)'0';
                chars++;
                len--;
                if (len > 0) {
                    if (*chars == (UniChar)'.') {
                        chars++;
                        len--;
                    } else {
                        digitsDone = true;
                    }
                }
            } else if (*chars == (UniChar)'.') {
                chars++;
                len--;
            } else {
                digitsDone = true;
            }
        }
    } else if (*chars == (UniChar)'.') {
        chars++;
        len--;
    } else {
        digitsDone = true;
    }

    // Now major1 and major2 contain first and second digit of the major version number as ints.
    // Now either len is 0 or chars points at the first char beyond the first decimal point.

    // Get the first minor version number.  
    if (len > 0 && !digitsDone) {
        if (_isDigit(*chars)) {
            minor1 = *chars - (UniChar)'0';
            chars++;
            len--;
            if (len > 0) {
                if (*chars == (UniChar)'.') {
                    chars++;
                    len--;
                } else {
                    digitsDone = true;
                }
            }
        } else {
            digitsDone = true;
        }
    }

    // Now minor1 contains the first minor version number as an int.
    // Now either len is 0 or chars points at the first char beyond the second decimal point.

    // Get the second minor version number. 
    if (len > 0 && !digitsDone) {
        if (_isDigit(*chars)) {
            minor2 = *chars - (UniChar)'0';
            chars++;
            len--;
        } else {
            digitsDone = true;
        }
    }

    // Now minor2 contains the second minor version number as an int.
    // Now either len is 0 or chars points at the build stage letter.

    // Get the build stage letter.  We must find 'd', 'a', 'b', or 'f' next, if there is anything next.
    if (len > 0) {
        if (*chars == (UniChar)'d') {
            stage = DEVELOPMENT_STAGE;
        } else if (*chars == (UniChar)'a') {
            stage = ALPHA_STAGE;
        } else if (*chars == (UniChar)'b') {
            stage = BETA_STAGE;
        } else if (*chars == (UniChar)'f') {
            stage = RELEASE_STAGE;
        } else {
            return 0;
        }
        chars++;
        len--;
    }

    // Now stage contains the release stage.
    // Now either len is 0 or chars points at the build number.

    // Get the first digit of the build number.
    if (len > 0) {
        if (_isDigit(*chars)) {
            build = *chars - (UniChar)'0';
            chars++;
            len--;
        } else {
            return 0;
        }
    }
    // Get the second digit of the build number.
    if (len > 0) {
        if (_isDigit(*chars)) {
            build *= 10;
            build += *chars - (UniChar)'0';
            chars++;
            len--;
        } else {
            return 0;
        }
    }
    // Get the third digit of the build number.
    if (len > 0) {
        if (_isDigit(*chars)) {
            build *= 10;
            build += *chars - (UniChar)'0';
            chars++;
            len--;
        } else {
            return 0;
        }
    }

    // Range check the build number and make sure we exhausted the string.
    if ((build > 0xFF) || (len > 0)) return 0;

    // Build the number
    theVers = major1 << 28;
    theVers += major2 << 24;
    theVers += minor1 << 20;
    theVers += minor2 << 16;
    theVers += stage << 8;
    theVers += build;

    return theVers;
}

