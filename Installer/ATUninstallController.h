// AppTapp Installer
// Copyright 2007 Nullriver, Inc.

#import "ATController.h"
#import "ATPackageDataSource.h"

@class ATInstaller;

@interface ATUninstallController : ATController {
	NSMutableArray		*	packages;
	NSMutableArray		*	packagesMaster;
	NSMutableArray		*	categories;

	UISectionList		*	sectionList;
	UITable			*	table;
	UIView				*	packageView;
	CGRect					mTableRectWithKeyboard;
	CGRect					mTableRectWithoutKeyboard;

	ATPackageDataSource	*	packageDataSource;
	UIPreferencesTable	*	detailTable;
	
	UISearchField*			searchField;
	UIKeyboard*				keyboard;
	BOOL					mDontClearSearch;
	UIAnimator*				animator;
}

// Methods
- (void)refresh;
- (void)showPackage:(NSDictionary *)aPackage;

- (void)_refilterPackages;
@end
