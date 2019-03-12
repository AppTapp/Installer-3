// AppTapp Framework
// Copyright 2007 Nullriver, Inc.

#import "ATDownloader.h"


@implementation ATDownloader

+ (BOOL)downloadPackage:(NSMutableDictionary *)aPackage notifying:(id)aDelegate {
	return [[self alloc] initWithPackage:aPackage withDelegate:aDelegate];
}

- (BOOL)initWithPackage:(NSMutableDictionary *)aPackage withDelegate:(id)aDelegate {
	if((self = [super init])) {
		delegate = aDelegate;
		package = [aPackage retain];

		downloadSize = [[aPackage packageSize] intValue];
		downloadBytes = 0;

		if([self checkPackageTempFile]) {
			[self autorelease];
			return NO;
		} else {
			NSString * outputFile = [package packageTempFile];
			if([[NSFileManager defaultManager] createFileAtPath:outputFile contents:nil attributes:nil]) {
				[delegate performSelector:@selector(packageDownload:statusChanged:) withObject:package withObject:@"Downloading package..."];

				downloadFile = [[NSFileHandle fileHandleForWritingAtPath:outputFile] retain];

				NSURL * packageURL = [NSURL URLWithString:[package packageLocation]];

				NSURLRequest * packageRequest = [NSURLRequest requestWithURL:packageURL];
				connection = [[NSURLConnection alloc] initWithRequest:packageRequest delegate:self];
			} else {
				NSLog(@"ATDownloader: Could not create output file: %@", outputFile);
				[self autorelease];
				return NO;
			}
		}
	}

	return YES;
}

- (void)dealloc {
	[connection release];
	[package release];

	[super dealloc];
}


#pragma mark -
#pragma mark Methods

- (BOOL)checkPackageTempFile {
	NSString * tempFile =[package packageTempFile];
	NSDictionary * attributes;

	if(attributes = [[NSFileManager defaultManager] fileAttributesAtPath:tempFile traverseLink:NO]) {
		NSString * fileSize = [[attributes objectForKey:NSFileSize] stringValue];

		[delegate performSelector:@selector(packageDownload:statusChanged:) withObject:package withObject:@"Checking package..."];
		[delegate performSelector:@selector(packageDownload:progressChanged:) withObject:package withObject:[NSNumber numberWithInt:0]];

		if([fileSize isEqualToString:[package packageSize]]) {
			if([package packageHash] != nil) {
				[delegate performSelector:@selector(packageDownload:progressChanged:) withObject:package withObject:[NSNumber numberWithInt:50]];
				NSString * hash = [[NSFileManager defaultManager] fileHashAtPath:tempFile];
				if(hash != nil && [hash isEqualToString:[package packageHash]]) {
					[delegate performSelector:@selector(packageDownload:progressChanged:) withObject:package withObject:[NSNumber numberWithInt:100]];

					return YES;
				} else {
					if(hash == nil) NSLog(@"ATDownloader: Could not calculate package hash!");
					else NSLog(@"ATDownloader: Invalid package hash \"%@\"!", hash);

					return NO;
				}
			} else {
				[delegate performSelector:@selector(packageDownload:progressChanged:) withObject:package withObject:[NSNumber numberWithInt:100]];
				NSLog(@"ATDownloader: Warning: This package has no hash defined! Packages without hashes will soon be deprecated!");

				return YES;
			}
		} else {
			NSLog(@"ATDownloader: Package size mismatch!");
			return NO;
		}
	} else {
		return NO;
	}
}

#pragma mark -
#pragma mark NSURL Download Delegate

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)newBytes {
	[downloadFile writeData:newBytes];
	downloadBytes += [newBytes length];

	int percent = ((double)downloadBytes / (double)downloadSize) * 100;

	[delegate performSelector:@selector(packageDownload:progressChanged:) withObject:package withObject:[NSNumber numberWithInt:percent]];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
	NSLog(@"ATDownloader: Downloaded package to: %@", [package packageTempFile]);

	[downloadFile closeFile];
	[downloadFile release];

	if([self checkPackageTempFile]) {
		NSLog(@"ATDownloader: Package downloaded successfully.");
		[delegate performSelector:@selector(packageDownloadCompleted:) withObject:package];
	} else { // Retry download? perhaps later.
		NSLog(@"ATDownloader: Package download failed!");
		[delegate performSelector:@selector(packageDownload:failedWithError:) withObject:package withObject:@"Package download failed!"];
	}

	[self autorelease];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)failReason {
	NSString * error = [NSString stringWithFormat:@"Package download failed: %@!", [[failReason userInfo] valueForKey:@"NSLocalizedDescription"]];
	NSLog(@"ATDownloader: %@", error);
	[delegate performSelector:@selector(packageDownload:failedWithError:) withObject:package withObject:error];
}

@end
