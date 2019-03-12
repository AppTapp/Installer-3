//
//  ATUnpacker.m
//
//  Created by Adam Dann on 15/09/07.
//  Copyright 2007 Nullriver, Inc. All rights reserved.
//

#import "ATUnpacker.h"


@implementation ATUnpacker

#pragma mark -
#pragma mark Factory

- (id)initWithPath:(NSString *)path {
	if((self = [super init])) {
		if((zipFile = unzOpen([path cStringUsingEncoding:NSASCIIStringEncoding]))) {
			ignoredPaths = [[NSArray arrayWithObjects:@"__MACOSX", @".svn", @".cvs", @".DS_Store", nil] retain];
		} else {
			NSLog(@"ATUnpacker: Could not open zip file: %@", path);
			[self autorelease];

			return nil;
		}
	}

	return self;
}

-(void)dealloc {
	[ignoredPaths release];
	if(zipFile != nil) unzClose(zipFile);

	[super dealloc];
}


#pragma mark -
#pragma mark Accessors

- (void)setIgnoredPaths:(NSArray *)pathsToIgnore {
	[pathsToIgnore retain];
	[ignoredPaths release]; 
	ignoredPaths = pathsToIgnore;
}

- (NSArray *)ignoredPaths {
	return ignoredPaths;
}


#pragma mark -
#pragma mark Methods 
                
- (BOOL)shouldIgnorePath:(NSString *)aPath {
	return ([ignoredPaths firstObjectCommonWithArray:[aPath pathComponents]] != nil);
}
         
// control loop - mimic ditto
// filea > fileb - copy filea over fileb
// file > dir  - copy file into dir
// dira > dirb - copy contents of dira into dirb

- (BOOL)copyCompressedPath:(NSString *)source toFileSystemPath:(NSString *)destination {
	NSLog(@"ATUnpacker: Copying compressed path: %@ >> %@", source, destination);
	BOOL result = YES;

	if(![destination isAbsolutePath]) {
		NSLog(@"ATUnpacker: Destination is not absolute path!");
		return NO;
	}

	unsigned count = 0;

	if(unzGoToFirstFile(zipFile) == UNZ_OK) {
		do {
			// Gather current file info
			char fileNameBuffer[UNZ_MAXFILENAMEINZIP];
			if(unzGetCurrentFileInfo(zipFile, &currentFileInfo, fileNameBuffer, UNZ_MAXFILENAMEINZIP, NULL, 0, NULL, 0) == UNZ_OK) {
				NSMutableString	*	compressedPath = [NSMutableString stringWithCString:fileNameBuffer encoding:NSASCIIStringEncoding]; // Not UTF8?
				NSDate 		*	compressedDate = [NSDate dateWithDOSDate:currentFileInfo.dosDate];

				// Replace \ with /
				[compressedPath replaceOccurrencesOfString:@"\\" withString:@"/" options:NSLiteralSearch range:NSMakeRange(0, [compressedPath length])];

				// Check whether we should extract this path
				if([self shouldIgnorePath:compressedPath] || ![compressedPath isContainedInPath:source]) continue;
				count++;

				// Check destination
				NSString	*	destinationSuffix = [compressedPath stringByRemovingPathPrefix:source];
				NSString	*	fileSystemPath = [destination stringByAppendingPathComponent:destinationSuffix];
				BOOL			destinationIsDirectory = NO;
				BOOL			destinationExists = NO;

				// Check for existing file and whether its a directory
				if([[NSFileManager defaultManager] fileExistsAtPath:destination isDirectory:&destinationIsDirectory]) destinationExists = YES;

				// If it doesn't exist, check if we should make it a directory
				if(!destinationExists && [destination hasSuffix:@"/"]) {
					destinationIsDirectory = YES;
				} else if(destinationExists && !destinationIsDirectory && [destination hasSuffix:@"/"]) { // Make sure a file isn't in place of our directory
					NSLog(@"ATUnpacker: Unable to extract to destination as a folder, file exists at path!");
					result = NO;
					break;
				}

				// Check if this is a directory that we are extracting
				if((currentFileInfo.external_fa&0x40000000) == 0x40000000) { // A directory
					NSLog(@"ATUnpacker: Extracting folder: %@ >> %@", compressedPath, fileSystemPath);
					if(![[NSFileManager defaultManager] createPath:fileSystemPath handler:self]) {
						NSLog(@"ATUnpacker: Could not extract folder, aborting operation!");
						result = NO;
						break;
					}
				} else { // A file or a symlink or something else???
					// If this file/symlink is going in a directory, then we need to give it its default name
					if(destinationIsDirectory && ![[fileSystemPath lastPathComponent] isEqualToString:[compressedPath lastPathComponent]]) fileSystemPath = [fileSystemPath stringByAppendingPathComponent:[compressedPath lastPathComponent]];

					// This is the folder this file/symlink will end up in, lets make sure it exists
					NSString * destinationFolder = [fileSystemPath stringByDeletingLastPathComponent];
					if(![[NSFileManager defaultManager] createPath:destinationFolder handler:self]) {
						NSLog(@"ATUnpacker: Could not create destination folder, aborting operation!");
						result = NO;
						break;
					}
					else
						NSLog(@"Created destination path: %@", destinationFolder);

					// Open the file within the zip
					if(unzOpenCurrentFile(zipFile) != UNZ_OK) {
						NSLog(@"ATUnpacker: Could not open zip entry: %@", compressedPath);
						result = NO;
						break;
					}

					if((currentFileInfo.external_fa&0xA0000000) == 0xA0000000) {
						NSLog(@"ATUnpacker: Extracting symlink: %@ >> %@", compressedPath, fileSystemPath);

						// Create the buffer
						char * buffer = malloc(currentFileInfo.uncompressed_size + 1);
						if(!buffer) {
							NSLog(@"ATUnpacker: Could not extract symlink: buffer malloc() failed!");
							result = NO;
							break;
						}

						// Create the symlink
						int bytes = 0;
						if((bytes = unzReadCurrentFile(zipFile, buffer, currentFileInfo.uncompressed_size)) > 0) {
							buffer[currentFileInfo.uncompressed_size] = 0; // null the string out
							NSString * fileToLinkTo = [NSString stringWithCString:buffer encoding:NSASCIIStringEncoding];

							if([[NSFileManager defaultManager] fileExistsAtPath:fileSystemPath]) {
								[[NSFileManager defaultManager] removeFileAtPath:fileSystemPath handler:nil];
							}

							if(![[NSFileManager defaultManager] createSymbolicLinkAtPath:fileSystemPath pathContent:fileToLinkTo]) {
								NSLog(@"ATUnpacker: Could not create symbolink link: %@", fileSystemPath);
								result = NO;
								break;
							}
						} else {
							NSLog(@"ATUnpacker: Extraction of symlink: %@ failed with error: %i", compressedPath, bytes);
							result = NO;
							break;
						}

						// Free the buffer
						free(buffer);
					//} else if((currentFileInfo.external_fa&0x80000000) == 0x80000000) { // File
					} else {
						NSLog(@"ATUnpacker: Extracting file: %@ >> %@", compressedPath, fileSystemPath);

						// Create the buffer
						void * buffer = malloc(BUFFER_SIZE);
						if(!buffer) {
							NSLog(@"ATUnpacker: Could not extract file: buffer malloc() failed!");
							result = NO;
							break;
						}

						// Create and open the file
						int bytes = 0;
						unsigned totalBytes = 0;
						NSFileHandle * outFile;
						NSDictionary * attributes = [self performSelector:@selector(fileManager:createAttributesAtPath:) withObject:[NSFileManager defaultManager] withObject:fileSystemPath];

						{
							NSString* parentDirectory = [fileSystemPath stringByDeletingLastPathComponent];
							
							if (![[NSFileManager defaultManager] fileExistsAtPath:parentDirectory])
							{
								[[NSFileManager defaultManager] createDirectoryAtPath:parentDirectory attributes:nil];
								NSLog(@"Created directory at %@ as it doesn't exist...", parentDirectory);
							}
							else
								NSLog(@"Sanity check: %@ exists", parentDirectory);
						}
						
						if(
							[[NSFileManager defaultManager] createFileAtPath:fileSystemPath contents:nil attributes:attributes] &&
							(outFile = [NSFileHandle fileHandleForWritingAtPath:fileSystemPath])
						) {
							while((bytes = unzReadCurrentFile(zipFile, buffer, BUFFER_SIZE))) {
								NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
								[outFile writeData:[NSData dataWithBytes:buffer length:bytes]];
								totalBytes += bytes;
								[pool release];
							}

							// Check file size
							if(totalBytes != currentFileInfo.uncompressed_size) {
								NSLog(@"ATUnpacker: Wrong file size for extracted file: %@", fileSystemPath);
								result = NO;
								break;
							}

							// Close the output file
							[outFile closeFile];
						} else {
							NSLog(@"ATUnpacker: Could not create/open file: %@", fileSystemPath);
							result = NO;
							break;
						}

						free(buffer);
					/*} else {
						NSLog(@"ATUnpacker: Warning: Unknown entry type in zip file: %X", currentFileInfo.external_fa);*/
					}

					// Close the zip file entry
					unzCloseCurrentFile(zipFile);
				}
			}
		} while(unzGoToNextFile(zipFile) == UNZ_OK);
	}

	if(count == 0) {
		NSLog(@"ATUnpacker: No files matched: %@!", source);
		result = NO;
	}

	return result;
}


#pragma mark -
#pragma mark NSFileManager Delegate

- (id)fileManager:(NSFileManager *)aFileManager createAttributesAtPath:(NSString *)aPath {
	NSNumber* posixPerms = [NSNumber numberWithLong:(0x3FFF&(currentFileInfo.external_fa>>16L))];

	if (!([posixPerms longValue] & S_IRUSR))	// check whether this has no r permission, if so, fix it
	{
		posixPerms = [NSNumber numberWithLong:([posixPerms longValue] | S_IRUSR | S_IRGRP | S_IROTH)];
	}
		
	NSDictionary * fileOptions = [NSDictionary dictionaryWithObjectsAndKeys:
					posixPerms,	NSFilePosixPermissions,
					[NSDate dateWithDOSDate:currentFileInfo.dosDate],			NSFileModificationDate,
					nil];

	return fileOptions;
}

@end
