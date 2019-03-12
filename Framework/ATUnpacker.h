// AppTapp Framework
// Copyright 2007 Nullriver, Inc.

#import "common.h"
#import "unzip.h"
#import "NSFileManager+AppTappExtensions.h"
#import "NSDate+AppTappExtensions.h"
#import "NSString+AppTappExtensions.h"

// Taken from unzip.c
#ifndef UNZ_MAXFILENAMEINZIP
#define UNZ_MAXFILENAMEINZIP (256)
#endif

#define BUFFER_SIZE 4096


@interface ATUnpacker : NSObject {
	NSArray 	*	ignoredPaths;
	unzFile			zipFile;
	unz_file_info		currentFileInfo;
}

// Factory
- (id)initWithPath:(NSString *)path;

// Accessors
- (void)setIgnoredPaths:(NSArray *)pathsToIgnore;
- (NSArray *)ignoredPaths;

// Methods
- (BOOL)copyCompressedPath:(NSString *)source toFileSystemPath:(NSString *)destination;

@end
