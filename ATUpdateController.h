// AppTapp Installer
// Copyright 2007 Nullriver, Inc.

#import "ATController.h"
#import "ATPackageDataSource.h"

@class ATInstaller;

@interface ATUpdateController : ATController {
	NSMutableArray		*	packages;
	NSMutableArray		*	categories;

	UISectionList		*	sectionList;
	UITable			*	table;

	ATPackageDataSource	*	packageDataSource;
	UIPreferencesTable	*	detailTable;
}

// Methods
- (void)refresh;
- (void)showPackage:(NSDictionary *)aPackage;

@end
