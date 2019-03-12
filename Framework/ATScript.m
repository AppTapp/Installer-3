// AppTapp Framework
// Copyright 2007 Nullriver, Inc.

#import "ATScript.h"

@implementation ATScript

#pragma mark -
#pragma mark Factory

- (id)init {
	if((self = [super init])) {
		package = [[NSMutableArray alloc] init];
		scriptCommands = [[NSMutableArray alloc] init];
		unpacker = nil;
		scriptAbortedGracefully = NO;
	}

	return self;
}

- (void)dealloc {
	[package release];
	[scriptCommands release];
	[unpacker release];

	[super dealloc];
}


#pragma mark -
#pragma mark Accessors

- (void)setDelegate:(id)aDelegate {
	delegate = aDelegate;
}

- (void)setPackage:(NSMutableDictionary *)aPackage {
	[aPackage retain];
	[package release];
	package = aPackage;

	if(unpacker != nil) [unpacker release];
	unpacker = [[ATUnpacker alloc] initWithPath:[aPackage packageTempFile]];
}

- (void)setScriptCommands:(NSArray *)commands {
	[scriptCommands removeAllObjects];
	[scriptCommands addObjectsFromArray:commands];
}

- (BOOL)scriptAbortedGracefully {
	return scriptAbortedGracefully;
}

- (int)dialect {
	return 300;
}

#pragma mark -
#pragma mark Methods

- (BOOL)run {
	return [self runScript:scriptCommands];
}

- (BOOL)runScript:(NSArray *)theScript {
	scriptAbortedGracefully = NO;

	NSLog(@"ATScript: Running script, dialect is: %i", [self dialect]);
	[delegate performSelector:@selector(scriptDidChangeProgress:) withObject:[NSNumber numberWithInt:0]];

	NSEnumerator * allCommands = [theScript objectEnumerator];
	NSArray * command;

	BOOL result = YES;
	int count = 0;
	int percent = 0;

	while((command = [allCommands nextObject])) {
		NSString * commandName = [command objectAtIndex:0];
		NSArray * arguments = [command subarrayWithRange:NSMakeRange(1, [command count] - 1)];

		NSLog(@"Executing script instruction: %@ with arguments %@", commandName, arguments);

		if([commandName isEqualToString:@"SetStatus"]) result = [self script_SetStatus:arguments];
		else if([commandName isEqualToString:@"Notice"]) result = [self script_Notice:arguments];
		else if([commandName isEqualToString:@"Confirm"]) result = [self script_Confirm:arguments];
		else if([commandName isEqualToString:@"AbortOperation"]) result = [self script_AbortOperation:arguments];
		else if([commandName isEqualToString:@"MinDialect"]) result = [self script_MinDialect:arguments];
		else if([commandName isEqualToString:@"FreeSpaceAtPath"]) result = [self script_FreeSpaceAtPath:arguments];
		else if([commandName isEqualToString:@"ExistsPath"]) result = [self script_ExistsPath:arguments];
		else if([commandName isEqualToString:@"IsLink"]) result = [self script_IsLink:arguments];
		else if([commandName isEqualToString:@"IsFolder"]) result = [self script_IsFolder:arguments];
		else if([commandName isEqualToString:@"IsFile"]) result = [self script_IsFile:arguments];
		else if([commandName isEqualToString:@"IsExecutable"]) result = [self script_IsExecutable:arguments];
		else if([commandName isEqualToString:@"IsWritable"]) result = [self script_IsWritable:arguments];
		else if([commandName isEqualToString:@"InstalledPackage"]) result = [self script_InstalledPackage:arguments];
		else if([commandName isEqualToString:@"InstallApp"]) result = [self script_InstallApp:arguments];
		else if([commandName isEqualToString:@"UninstallApp"]) result = [self script_UninstallApp:arguments];
		else if([commandName isEqualToString:@"CopyPath"]) result = [self script_CopyPath:arguments];
		else if([commandName isEqualToString:@"MovePath"]) result = [self script_MovePath:arguments];
		else if([commandName isEqualToString:@"LinkPath"]) result = [self script_LinkPath:arguments];
		else if([commandName isEqualToString:@"RemovePath"]) result = [self script_RemovePath:arguments];
		else if([commandName isEqualToString:@"Exec"]) result = [self script_Exec:arguments];
		else if([commandName isEqualToString:@"ExecNoError"]) result = [self script_ExecNoError:arguments];
		else if([commandName isEqualToString:@"If"]) result = [self script_If:arguments];
		else if([commandName isEqualToString:@"IfNot"]) result = [self script_IfNot:arguments];
		else if([commandName isEqualToString:@"AddSource"]) result = [self script_AddSource:arguments];
		else if([commandName isEqualToString:@"RemoveSource"]) result = [self script_RemoveSource:arguments];
		else if([commandName isEqualToString:@"RestartSpringBoard"]) result = [self script_RestartSpringBoard];
		else if([commandName isEqualToString:@"PlatformNameIs"]) result = [self script_PlatformNameIs:arguments];
		else if([commandName isEqualToString:@"FirmwareVersionIs"]) result = [self script_FirmwareVersionIs:arguments];
		else {
			// The error message should be improved for If/IfNot
			NSString * error = [NSString stringWithFormat:@"Error in script command %i: %@", count + 1, commandName];
			NSLog(@"ATScript: %@", error);
			[self script_AbortOperation:[NSArray arrayWithObject:error]]; 
			result = NO;
		}

		if(result == NO) break;

		count++;
		percent = (count / [[NSNumber numberWithUnsignedInt:[theScript count]] doubleValue]) * 100;
		[delegate performSelector:@selector(scriptDidChangeProgress:) withObject:[NSNumber numberWithInt:percent]];
		[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.01f]];
	}

	return result;
}


#pragma mark - 
#pragma mark Script Commands

- (BOOL)script_SetStatus:(NSArray *)arguments {
	if([arguments count] != 1) return NO; // SetStatus(text)

	[delegate performSelector:@selector(statusChanged:) withObject:[arguments objectAtIndex:0]];

	return YES;
}

- (BOOL)script_Notice:(NSArray *)arguments {
	if([arguments count] != 1) return NO; // Notice(text)

	[delegate performSelector:@selector(scriptNotice:) withObject:[arguments objectAtIndex:0]];

	while(![[delegate performSelector:@selector(scriptCanContinue)] boolValue]) {
		[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1.0f]];
	}

	return YES;
}

- (BOOL)script_Confirm:(NSArray *)arguments {
	if([arguments count] != 3) return NO; // Confirm(text, button1, button2)

	[delegate performSelector:@selector(scriptConfirm:) withObject:arguments];

	while(![[delegate performSelector:@selector(scriptCanContinue)] boolValue]) {
		[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1.0f]];
	}

	unsigned button = [[delegate performSelector:@selector(scriptConfirmedButton)] unsignedIntValue];

	if(button == 1) return YES;
	else {
		scriptAbortedGracefully = YES;
		return NO;
	}
}

- (BOOL)script_AbortOperation:(NSArray *)arguments {
	if([arguments count] != 1) return NO; // AbortOperation(text)

	[delegate performSelector:@selector(scriptError:) withObject:[arguments objectAtIndex:0]];

	while(![[delegate performSelector:@selector(scriptCanContinue)] boolValue]) {
		[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1.0f]];
	}

	scriptAbortedGracefully = YES;

	return NO;
}

- (BOOL)script_MinDialect:(NSArray *)arguments {
	if([arguments count] != 1) return NO; // MinDialect(dialectNumber)

	return ([[arguments objectAtIndex:0] intValue] > [self dialect]);
}

- (BOOL)script_FreeSpaceAtPath:(NSArray *)arguments {
	if([arguments count] != 2) return NO; // FreeSpaceAtPath(path, minimumSpace)

	NSString * path = [[arguments objectAtIndex:0] stringByExpandingSpecialPathsInPath];

	return [[[NSFileManager defaultManager] freeSpaceAtPath:path] unsignedLongLongValue] >= (unsigned long long)([[arguments objectAtIndex:1] intValue] * 1024);
}

- (BOOL)script_ExistsPath:(NSArray *)arguments {
	if([arguments count] != 1) return NO; // ExistsPath(path)
	NSString * path = [[arguments objectAtIndex:0] stringByExpandingSpecialPathsInPath];

	return [[NSFileManager defaultManager] fileExistsAtPath:path];
}

- (BOOL)script_IsLink:(NSArray *)arguments {
	if([arguments count] != 1) return NO; // IsLink(path)
	NSString * path = [[arguments objectAtIndex:0] stringByExpandingSpecialPathsInPath];

	return [[[[NSFileManager defaultManager] attributesOfItemAtPath:path error:nil] valueForKey:NSFileTypeSymbolicLink] boolValue];
}

- (BOOL)script_IsFolder:(NSArray *)arguments {
	if([arguments count] != 1) return NO; // IsFolder(path)
	NSString * path = [[arguments objectAtIndex:0] stringByExpandingSpecialPathsInPath];

	return [[[[NSFileManager defaultManager] attributesOfItemAtPath:path error:nil] valueForKey:NSFileTypeDirectory] boolValue];
}

- (BOOL)script_IsFile:(NSArray *)arguments {
	if([arguments count] != 1) return NO; // IsFile(path)
	NSString * path = [[arguments objectAtIndex:0] stringByExpandingSpecialPathsInPath];

	return [[[[NSFileManager defaultManager] attributesOfItemAtPath:path error:nil] valueForKey:NSFileTypeRegular] boolValue];
}

- (BOOL)script_IsExecutable:(NSArray *)arguments {
	if([arguments count] != 1) return NO; // IsExecutable(path)
	NSString * path = [[arguments objectAtIndex:0] stringByExpandingSpecialPathsInPath];

	return [[NSFileManager defaultManager] isExecutableFileAtPath:path];
}

- (BOOL)script_IsWritable:(NSArray *)arguments {
	if([arguments count] != 1) return NO; // IsWritable(path)
	NSString * path = [[arguments objectAtIndex:0] stringByExpandingSpecialPathsInPath];

	return [[NSFileManager defaultManager] isWritableFileAtPath:path];
}

- (BOOL)script_InstalledPackage:(NSArray *)arguments {
	if([arguments count] != 1) return NO; // InstalledPackage(packageBundleIdentifier)

	return [[delegate performSelector:@selector(scriptIsPackageInstalled:) withObject:[arguments objectAtIndex:0]] boolValue];
}

- (BOOL)script_InstallApp:(NSArray *)arguments {
	if([arguments count] != 1) return NO; // InstallApp(source)

	NSArray * newArguments = [NSArray arrayWithObjects:
					[arguments objectAtIndex:0],
					[[ATPlatform applicationsPath] stringByAppendingPathComponent:[arguments objectAtIndex:0]], 
				nil];

	NSLog(@"ATScript: Installing App: %@", [newArguments objectAtIndex:1]);
	return [self script_CopyPath:newArguments];
}

- (BOOL)script_UninstallApp:(NSArray *)arguments {
	if([arguments count] != 1) return NO; // UninstallApp(appBundle)

	NSString * appBundle = [arguments objectAtIndex:0];

	if(![appBundle isEqualToString:@""]) {
		NSArray * newArguments = [NSArray arrayWithObject:[[ATPlatform applicationsPath] stringByAppendingPathComponent:appBundle]];
		NSLog(@"ATScript: Uninstalling App: %@", [newArguments objectAtIndex:0]);
		return [self script_RemovePath:newArguments];
	} else {
		NSLog(@"ATScript: Cannot UninstallApp, no bundle specified!");
		return NO;
	}
}

- (BOOL)script_CopyPath:(NSArray *)arguments {
	if([arguments count] != 2) return NO; // CopyPath(source, destination)

	NSString * path1 = [[arguments objectAtIndex:0] stringByExpandingSpecialPathsInPath];
	NSString * path2 = [[arguments objectAtIndex:1] stringByExpandingSpecialPathsInPath];

	if([path1 isAbsolutePath]) {
		NSLog(@"ATScript: Copying absolute path: %@ to: %@", path1, path2);
		return [[NSFileManager defaultManager] copyPath:path1 toPath:path2 handler:nil];
	} else {
		return [unpacker copyCompressedPath:path1 toFileSystemPath:path2];
	}
}

- (BOOL)script_MovePath:(NSArray *)arguments {
	if([self script_CopyPath:arguments]) {
		return [self script_RemovePath:[NSArray arrayWithObject:[arguments objectAtIndex:0]]];
	}

	return NO;
}

- (BOOL)script_LinkPath:(NSArray *)arguments {
	if([arguments count] != 2) return NO; // LinkPath(fromPath, toPath)

	NSString * path1 = [[arguments objectAtIndex:0] stringByExpandingSpecialPathsInPath];
	NSString * path2 = [[arguments objectAtIndex:1] stringByExpandingSpecialPathsInPath];

	return [[NSFileManager defaultManager] linkPath:path1 toPath:path2 handler:nil];
}

- (BOOL)script_RemovePath:(NSArray *)arguments {
	if([arguments count] < 1) return NO; // RemovePath(path, ...)

	NSEnumerator * allArguments = [arguments objectEnumerator];
	NSString * path;
	while((path = [[allArguments nextObject] stringByExpandingSpecialPathsInPath])) {
		// sanity check
		if([path isEqualToString:@"/"]) return NO; // hell no

		// Fail only if the file exists and cannot be removed
		if(
			[[NSFileManager defaultManager] fileExistsAtPath:path] &&
			![[NSFileManager defaultManager] removeFileAtPath:path handler:nil]
		) return NO;
	}

	return YES;
}

- (BOOL)script_Exec:(NSArray *)arguments {
	if([arguments count] != 1) return NO; // Exec(path)

	arguments = [[arguments objectAtIndex:0] componentsSeparatedByString:@" "];

	NSString * command = [[arguments objectAtIndex:0] stringByExpandingSpecialPathsInPath];

	NSArray * commandArguments = arguments; //[NSMutableArray arrayWithObject:[command lastPathComponent]];
	//[commandArguments addObjectsFromArray:[arguments subarrayWithRange:NSMakeRange(1, [arguments count] - 1)]];

	// generate argv
	unsigned arrayCount = [commandArguments count];
	char *argv[arrayCount + 1];
	int argvCount;

	for (argvCount = 0; argvCount < arrayCount; argvCount++) {
		NSString *theString = (NSString *)[commandArguments objectAtIndex:argvCount];
		unsigned int stringLength = [theString length];

		argv[argvCount] = malloc((stringLength + 1) * sizeof(char));
		snprintf(argv[argvCount], stringLength + 1, "%s", [theString cString]);
	}
	argv[argvCount] = NULL;

	// begin

	pid_t pid;
	pid_t result;
	int status;

	pid = fork();

	if(pid == 0) {
		execv([command cString], argv);
		exit(1);
	} else if(pid < 0) {
		NSLog(@"Error forking child process!");
	} else {
		while((result = wait(&status))) { if(result == pid || result == -1) break; }
		if(status == 0) return YES;
	}

	return NO;
}

- (BOOL)script_ExecNoError:(NSArray *)arguments {
	[self script_Exec:arguments];

	return YES;
}

- (BOOL)script_If:(NSArray *)arguments {
	if([arguments count] != 2) return NO; // If(evalScript, trueScript)
	
	NSArray * evalScript = [arguments objectAtIndex:0];
	NSArray * trueScript = [arguments objectAtIndex:1];

	if(
		![evalScript respondsToSelector:@selector(sortedArrayHint)] ||
		![trueScript respondsToSelector:@selector(sortedArrayHint)]
	) {
		NSLog(@"Error: Invalid arguments to If!");
		return NO;
	}

	if([self runScript:evalScript]) {
		return [self runScript:trueScript];
	}

	scriptAbortedGracefully = NO;

	return YES;
}

- (BOOL)script_IfNot:(NSArray *)arguments {
	if([arguments count] != 2) return NO; // If(evalScript, falseScript)
	
	NSArray * evalScript = [arguments objectAtIndex:0];
	NSArray * falseScript = [arguments objectAtIndex:1];

	if(
		![evalScript respondsToSelector:@selector(sortedArrayHint)] ||
		![falseScript respondsToSelector:@selector(sortedArrayHint)]
	) {
		NSLog(@"Error: Invalid arguments to IfNot!");
		return NO;
	}

	if(![self runScript:evalScript]) {
		return [self runScript:falseScript];
	}

	scriptAbortedGracefully = NO;

	return YES;
}

- (BOOL)script_AddSource:(NSArray *)arguments {
	if([arguments count] != 1) return NO; // AddSource(url)

	[delegate performSelector:@selector(scriptAddSource:) withObject:[arguments lastObject]];

	return YES;
}

- (BOOL)script_RemoveSource:(NSArray *)arguments {
	if([arguments count] != 1) return NO; // RemoveSource(url)

	[delegate performSelector:@selector(scriptRemoveSource:) withObject:[arguments lastObject]];

	return YES;
}

- (BOOL)script_RestartSpringBoard {
	// RestartSpringBoard()
	[delegate performSelector:@selector(scriptRestartSpringBoard)];

	return YES;
}

- (BOOL)script_PlatformNameIs:(NSArray *)arguments {
	// PlatformNameIs(arrayOfVersions)
	return [[arguments objectAtIndex:0] containsObject:[ATPlatform platformName]];
}

- (BOOL)script_FirmwareVersionIs:(NSArray *)arguments {
	// FirmwareVersionIs(arrayOfVersions)
	return [[arguments objectAtIndex:0] containsObject:[ATPlatform firmwareVersion]];
}

@end
