// AppTapp Framework
// Copyright 2007 Nullriver, Inc.

#import "common.h"
#import "ATPlatform.h"
#import "ATUnpacker.h"
#import "NSDictionary+AppTappPackage.h"


@class ATPackageManager;


@interface ATScript : NSObject {
	id				delegate;
	NSMutableDictionary	*	package;
	NSMutableArray		*	scriptCommands;
	ATUnpacker		*	unpacker;
	NSArray			*	protectedPaths;
	BOOL				scriptAbortedGracefully;
}

// Accessors
- (void)setDelegate:(id)aDelegate;
- (void)setPackage:(NSMutableDictionary *)aPackage;
- (void)setScriptCommands:(NSArray *)commands;
- (BOOL)scriptAbortedGracefully;
- (int)dialect;

// Methods
- (BOOL)run;
- (BOOL)runScript:(NSArray *)theScript;

// Script Commands
- (BOOL)script_SetStatus:(NSArray *)arguments;
- (BOOL)script_Notice:(NSArray *)arguments;
- (BOOL)script_Confirm:(NSArray *)arguments;
- (BOOL)script_AbortOperation:(NSArray *)arguments;
- (BOOL)script_MinDialect:(NSArray *)arguments;
- (BOOL)script_FreeSpaceAtPath:(NSArray *)arguments;
- (BOOL)script_ExistsPath:(NSArray *)arguments;
- (BOOL)script_IsLink:(NSArray *)arguments;
- (BOOL)script_IsFolder:(NSArray *)arguments;
- (BOOL)script_IsFile:(NSArray *)arguments;
- (BOOL)script_IsExecutable:(NSArray *)arguments;
- (BOOL)script_IsWritable:(NSArray *)arguments;
- (BOOL)script_InstalledPackage:(NSArray *)arguments;
- (BOOL)script_InstallApp:(NSArray *)arguments;
- (BOOL)script_UninstallApp:(NSArray *)arguments;
- (BOOL)script_CopyPath:(NSArray *)arguments;
- (BOOL)script_MovePath:(NSArray *)arguments;
- (BOOL)script_LinkPath:(NSArray *)arguments;
- (BOOL)script_RemovePath:(NSArray *)arguments;
- (BOOL)script_Exec:(NSArray *)arguments;
- (BOOL)script_ExecNoError:(NSArray *)arguments;
- (BOOL)script_If:(NSArray *)arguments;
- (BOOL)script_IfNot:(NSArray *)arguments;
- (BOOL)script_AddSource:(NSArray *)arguments;
- (BOOL)script_RemoveSource:(NSArray *)arguments;
- (BOOL)script_RestartSpringBoard;
- (BOOL)script_PlatformNameIs:(NSArray *)arguments;
- (BOOL)script_FirmwareVersionIs:(NSArray *)arguments;

@end
