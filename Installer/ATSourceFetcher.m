// AppTapp Framework
// Copyright 2007 Nullriver, Inc.
// Additions Copyright ©2008, RiP Dev

#import "ATSourceFetcher.h"
#import "NSDictionary+AppTappSource.h"
#import "ATPlatform.h"

@implementation ATSourceFetcher

+ (id)refreshSource:(NSDictionary *)aSource notifying:(id)aDelegate {
	return [[self alloc] initWithSource:aSource withDelegate:aDelegate];
}

- (id)initWithSource:(NSDictionary *)aSource withDelegate:(id)aDelegate {
	if((self = [super init])) {
		delegate = aDelegate;
		source = [aSource retain];

		char* tempdir = tempnam("/tmp", "Installer_");
		if (!tempdir)
			return nil;

		NSString * outputFile = [[NSFileManager defaultManager] stringWithFileSystemRepresentation:tempdir length:strlen(tempdir)];
		if([[NSFileManager defaultManager] createFileAtPath:outputFile contents:nil attributes:nil]) {
			downloadFile = [[NSFileHandle fileHandleForWritingAtPath:outputFile] retain];

			fileName = [outputFile retain];
			
		} else {
			NSLog(@"ATSourceFetcher: Could not create output file: %@", outputFile);
			[self autorelease];
			return nil;
		}
	}

	return self;
}

- (void)dealloc {
	[connection release];
	[source release];
	[fileName release];

	[super dealloc];
}

- (void)start
{
	NSURL * sourceURL = [NSURL URLWithString:[source sourceLocation]];

	NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:sourceURL cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:30.0];
	[request setValue:__USER_AGENT__ forHTTPHeaderField:@"User-Agent"];
	
	connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
}

#pragma mark -
#pragma mark NSURL Download Delegate

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)newBytes {
	[downloadFile writeData:newBytes];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
	NSLog(@"ATSourceFetcher: Finished fetching source %@ (into %@)", [source sourceLocation], fileName);

	[downloadFile closeFile];
	[downloadFile release];
	
	NSDictionary* sourceIndex = [NSDictionary dictionaryWithContentsOfFile:fileName];
	
	if (sourceIndex)
	{
		if ([delegate respondsToSelector:@selector(sourceRefreshDidComplete:index:)])
			[delegate performSelector:@selector(sourceRefreshDidComplete:index:) withObject:source withObject:sourceIndex];
	}
	else
	{
		NSError* err = [NSError errorWithDomain:NSCocoaErrorDomain code:13 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:@"Cannot create source index for %@", [source sourceName]], NSLocalizedDescriptionKey, source, @"Source", nil]];
		
		[delegate performSelector:@selector(sourceRefreshDidFail:withError:) withObject:source withObject:err];
	}

	[[NSFileManager defaultManager] removeFileAtPath:fileName handler:nil];		// remove the temp file

	[self autorelease];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)failReason {
	NSLog(@"ATSourceFetcher: %@ failed with %@", [source sourceLocation], failReason);
	[delegate performSelector:@selector(sourceRefreshDidFail:withError:) withObject:source withObject:failReason];
}

/*- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
	NSLog(@"ATSourceFetcher: %@ didReceiveResponse:%@ (exp length = %u, mime = %@)", [source sourceLocation], response, [response expectedContentLength], [response MIMEType]);	
}
*/

/*
- (NSURLRequest *)connection:(NSURLConnection *)connection willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)response
{
	NSLog(@"-[%@ willSendRequest:%@]", [source sourceLocation], request);
	
	return request;
}
*/

- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
//	NSLog(@"-[%@ didReceiveAuthenticationChallenge:%@]", [source sourceLocation], challenge);
}

- (void)connection:(NSURLConnection *)connection didCancelAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
//	NSLog(@"-[%@ didCancelAuthenticationChallenge:%@]", [source sourceLocation], challenge);
}


@end
