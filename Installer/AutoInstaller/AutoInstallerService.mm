#import <Foundation/Foundation.h>
#import "ATPackageManager.h"

@interface AutoInstallerService : NSObject
{
	ATPackageManager* mPM;
}

- (void)doMmmBop:(id)sender;
@end

int main(int argc, char* argv[])
{
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	
	seteuid(501); // make us a mobile user
	
	AutoInstallerService* svc = [[AutoInstallerService alloc] init];
	
	if (svc)
	{
		[svc doMmmBop:nil];
		[svc release];
	}
	
	[pool release];
	
	return 1;
}

@implementation AutoInstallerService
- (id)init
{
	if(self = [super init])
	{
		mPM = [ATPackageManager sharedPackageManager];
		[mPM setDelegate:self];
	}
	return self;
}

- (void)doMmmBop:(id)sender
{
	if ([self autoPwnerIsInstalled])
	{
		NSLog(@"BootNeuter is installed, we'll come back next reboot.");
		return;
	}
	
	[mPM refreshSource:[self localSource]];
	
	NSMutableArray* packagesToInstall = [self localSourcePackages];
	
	if (!packagesToInstall or ![packagesToInstall count])
	{
		NSLog(@"[AutoInstaller] No packages to install. Exiting.");
		return;
	}
	
	NSString* alPath = @"/usr/local/bin/AutoInstaller.app/AutoInstaller";
	
	if (![[NSFileManager defaultManager] fileExistsAtPath:alPath])
	{
		NSLog(@"[AutoInstaller] No GUI worker app found at %@", alPath);
		return;
	}
	
	// Sublaunch the AutoInstaller
	NSLog(@"[AutoInstaller] Launching GUI/Worker app, we've got work to do (%u packages to install).", [packagesToInstall count]);
	pid_t child;
	
	if (child = fork())
	{
		int exitStatus = 0;
		
		waitpid(child, &exitStatus, 0);
	}
	else
	{
		// Set environment
		NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
		
		// sublaunch task
		const char* taskPath = [[NSFileManager defaultManager] fileSystemRepresentationWithPath:alPath];
		
		NSLog(@"Launching %s...", taskPath);
		
		seteuid(0);
		
		execl(taskPath, taskPath, NULL);
		
		[pool release];
		exit(0);
	}
}

- (BOOL)autoPwnerIsInstalled
{
	return [[NSFileManager defaultManager] fileExistsAtPath:@"/System/Library/LaunchDaemons/com.devteam.bootneuter.auto.plist"];
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
}

- (void)packageManager:(id)fp8 statusChanged:(id)fp12
{
}

- (void)packageManager:(id)fp8 finishedQueueWithResult:(id)fp12
{
}

- (void)packageManager:(id)fp8 didAddSource:(id)fp12
{	
}

- (void)packageManager:(id)fp8 didRemoveSource:(id)fp12
{
}

- (void)packageManager:(id)fp8 issuedNotice:(id)fp12
{
}

- (void)packageManager:(id)fp8 issuedError:(id)fp12
{
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
@end
