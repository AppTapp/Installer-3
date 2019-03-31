// AppTapp Installer
// Copyright 2007 Nullriver, Inc.

#import "ATController.h"
#import "ATPackageDataSource.h"


@class ATInstaller;

@interface ATSourcesController : ATController {
	UISectionList		*	sectionList;
	UITable			*	table;
	ATPackageDataSource	*	packageDataSource;
	UIPreferencesTable	*	detailTable;

	UIAlertSheet		*	addSourceSheet;
	id				addSourceSheetTextField;

	BOOL				editMode;
	NSDictionary		*	selectedSource;
}

@end
