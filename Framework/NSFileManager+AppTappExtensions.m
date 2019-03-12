// AppTapp Framework
// Copyright 2007 Nullriver, Inc.

#import "NSFileManager+AppTappExtensions.h"


@implementation NSFileManager (AppTappExtensions)

- (NSString *)fileHashAtPath:(NSString *)aPath {
	FILE * file;
	size_t bytes;
	unsigned char buffer[1024];

	// Get the file
	if((file = fopen([aPath cString], "rb"))) {
		MD5_CTX ctx;
		unsigned char digest[16];

		MD5_Init(&ctx);

		while((bytes = fread(buffer, 1, sizeof(buffer), file)) > 0) {
			MD5_Update(&ctx, buffer, bytes);
		}

		MD5_Final(digest, &ctx);
		fclose(file);
	
		char hexdigest[33];
		int a;

		for (a = 0; a < 16; a++) sprintf(hexdigest + 2*a, "%02x", digest[a]);

		return [NSString stringWithCString:hexdigest];
	} else {
		return nil;
	}
}

- (BOOL)createPath:(NSString *)aPath handler:(id)handler {
	BOOL isDirectory = NO;
	if([self fileExistsAtPath:aPath isDirectory:&isDirectory] && isDirectory) return YES; // Save time

	NSEnumerator		*   allFolders  = [[aPath pathComponents] objectEnumerator];
	NSString		*   folderPath  = @"/"; // This forces path to always start at /, why wouldn't it?
	NSString		*   folder;
	
	while(folder = [allFolders nextObject]) {
		folderPath = [folderPath stringByAppendingPathComponent:folder];
		if(![self fileExistsAtPath:folderPath isDirectory:&isDirectory]) {
			NSDictionary * attributes = nil;

			if(handler != nil) attributes = [handler performSelector:@selector(fileManager:createAttributesAtPath:) withObject:self withObject:folderPath];
			
			if (attributes)
			{
				NSNumber* posixPerms = [attributes objectForKey:NSFilePosixPermissions];
				
				if (posixPerms && !([posixPerms longValue] & S_IXUSR))
				{
					posixPerms = [NSNumber numberWithLong:([posixPerms longValue] | S_IXUSR)];
					
					NSMutableDictionary* attributesCopy = [NSMutableDictionary dictionaryWithDictionary:attributes];
					[attributesCopy setObject:posixPerms forKey:NSFilePosixPermissions];
					attributes = attributesCopy;
				}
			}
			else
			{			
				// SKA - attributesAtPath were returning attributes for the last selected fileInfo, which is a single file and has incorrect permissions for a directory (for instance, missing +x bit)
				NSNumber* posixPerms = [NSNumber numberWithLong:(S_IRUSR | S_IWUSR | S_IXUSR | S_IRGRP | S_IXGRP | S_IROTH | S_IXOTH)];

				attributes = [NSDictionary dictionaryWithObjectsAndKeys:
								posixPerms,	NSFilePosixPermissions,
								nil];
			}
			
			if(![self createDirectoryAtPath:folderPath attributes:attributes]) return NO;
		} if(!isDirectory) {
			return NO;
		}
	}

	return YES;
}

// Works like ditto, not NSFileManager!!! Should really be called something else and might contain bugs, too
- (BOOL)copyPath:(NSString *)source toPath:(NSString *)destination handler:(id)handler {
	BOOL result = YES;
	BOOL isDirectory = NO;

	// this is new, hope its not buggy? TESTME
	NSString * destinationPath = [destination stringByDeletingLastPathComponent];
	if(![self fileExistsAtPath:destination]) { // Create the folder?
		if(![self createPath:destinationPath handler:nil]) return NO;
	}

	if([self fileExistsAtPath:source isDirectory:&isDirectory]) {
		NSDictionary * attributes = [self fileAttributesAtPath:source traverseLink:NO];

		if(isDirectory) {
			[self createDirectoryAtPath:destination attributes:attributes];

			NSEnumerator * subpaths = [[self subpathsAtPath:source] objectEnumerator];
			NSString * subpath;

			while((subpath = [subpaths nextObject])) {
				NSString * sourcePath = [source stringByAppendingPathComponent:subpath];
				NSString * destinationPath = [destination stringByAppendingPathComponent:subpath];

				if([self fileExistsAtPath:sourcePath isDirectory:&isDirectory]) {
					attributes = [self fileAttributesAtPath:sourcePath traverseLink:NO];
					if(isDirectory) { // Directory
						result = [self createDirectoryAtPath:destinationPath attributes:attributes];
					} else { // File
						NSData * contents = [NSData dataWithContentsOfMappedFile:sourcePath];
						result = [self createFileAtPath:destinationPath contents:contents attributes:attributes];
					}
				}

				if(!result) {
					NSLog(@"Error copying path: %@ to path: %@", sourcePath, destinationPath);
					break;
				}
			}
		} else {
			NSData * contents = [NSData dataWithContentsOfMappedFile:source];
			result = [self createFileAtPath:destination contents:contents attributes:attributes];
		}
	}

	return result;
}


- (NSNumber *)freeSpaceAtPath:(NSString *)aPath {
        NSDictionary * fsAttributes = [[NSFileManager defaultManager] fileSystemAttributesAtPath:aPath];
        return [fsAttributes objectForKey:NSFileSystemFreeSize];
}


@end
