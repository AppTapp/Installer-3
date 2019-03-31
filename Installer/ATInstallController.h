// AppTapp Installer
// Copyright 2007 Nullriver, Inc.

#import "ATController.h"
#import "ATPackageDataSource.h"


@class ATInstaller;

@interface ATInstallController : ATController {
	NSMutableArray		*	packages;
	NSMutableArray		*	packagesMaster;
	NSMutableArray		*	categories;
	int				selectedCategory;
	NSMutableDictionary	*	selectedPackage;

	NSMutableArray*			sections;

	UITable			*	categoryTable;
	UISectionList		*	packageSectionList;
	UITable			*	packageTable;
	UIView			*		packageView;
	ATPackageDataSource	*	packageDataSource;
	UIPreferencesTable	*	detailTable;
	
	UISearchField*			searchField;
	UIKeyboard*				keyboard;
	BOOL					mDontClearSearch;
	UIAnimator*				animator;

	CGRect					mTableRectWithKeyboard;
	CGRect					mTableRectWithoutKeyboard;
}

// Methods
- (void)refresh;
- (void)showPackage:(NSDictionary *)aPackage;

- (void)_recreateSections;
- (void)_refilterPackages;
@end
