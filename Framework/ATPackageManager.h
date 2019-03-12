// AppTapp Framework
// Copyright 2007 Nullriver, Inc.

#import "common.h"
#import "NSNumber+AppTappExtensions.h"
#import "NSArray+AppTappSources.h"
#import "NSArray+AppTappPackages.h"
#import "NSArray+AppTappQueue.h"
#import "NSDictionary+AppTappSource.h"
#import "NSDictionary+AppTappPackage.h"
#import "NSDictionary+AppTappQueue.h"
#import "ATDownloader.h"
#import "ATScript.h"
#import "ATPlatform.h"

@interface ATPackageManager : NSObject {
	BOOL				upgradeWasPerformed;

	NSMutableArray		*	trustedSources;
	NSMutableArray		*	packageSources;
	NSMutableArray		*	localPackages;
	NSMutableArray		*	remotePackages;

	NSMutableArray		*	installablePackages;
	NSMutableArray		*	updateablePackages;
	NSMutableArray		*	uninstallablePackages;

	NSMutableArray		*	packageQueue;
	BOOL				queueOnHold;
	BOOL				springBoardNeedsRestart;
	BOOL				sourcesModified;
	
	BOOL				initialSortDone;		// SKA 03/14/08
	unsigned int		sourcesRefreshed;		// SKA 04/10/08
	
	ATScript		*	script;

	id				delegate;
	
@private
	NSMutableDictionary		*	sourceRefreshQueue;
}

// Factory
+ (id)sharedPackageManager;

// Accessors
- (NSMutableArray *)trustedSources;
- (NSMutableArray *)packageSources;
- (NSMutableArray *)localPackages;
- (NSMutableArray *)remotePackages;
- (NSMutableArray *)installablePackages;
- (NSMutableArray *)updateablePackages;
- (NSMutableArray *)uninstallablePackages;
- (NSMutableArray *)packageQueue;
- (BOOL)hasQueuedPackages;
- (BOOL)queueContainsPackage:(NSMutableDictionary *)aPackage;

// Methods
- (NSMutableDictionary *)ownPackage;
- (void)setDelegate:(id)aDelegate;
- (void)statusChanged:(NSString *)status;
- (void)progressChanged:(NSNumber *)progress;
- (BOOL)performUpgrade;
- (BOOL)refreshIsNeeded;
- (void)resort;
- (void)saveState;
- (BOOL)removeSourceWithLocation:(NSString *)sourceLocation;
- (BOOL)addSourceWithLocation:(NSString *)sourceLocation;
- (BOOL)refreshTrustedSources;
- (BOOL)refreshAllSources;
- (BOOL)refreshSource:(NSMutableDictionary *)aSource;
- (BOOL)removeStalePackagesForSource:(NSMutableDictionary *)aSource;
- (BOOL)clearQueue;
- (BOOL)dequeuePackage:(NSMutableDictionary *)aPackage;
- (BOOL)queuePackage:(NSMutableDictionary *)aPackage forOperation:(NSString *)anOperation;
- (BOOL)processQueue;
- (BOOL)performOperation:(NSString *)anOperation onPackage:(NSMutableDictionary *)aPackage;

// Utility functions
- (BOOL)localVersionIsOlder:(NSString*)localVersion comparedToRemoteVersion:(NSString*)remoteVersion;
- (NSString*)_normalizeVersion:(NSString*)version;

@end
