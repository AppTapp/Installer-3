// AppTapp Framework
// Copyright 2007 Nullriver, Inc.

#import "NSNumber+AppTappExtensions.h"


@implementation NSNumber (AppTappExtensions)

- (NSString *)byteSizeDescription {
	double dBytes = [self doubleValue];

	if(dBytes == 0) {
		return @"0 bytes";
	} else if(dBytes <= pow(2, 10)) {
		return [NSString stringWithFormat:@"%0.0f bytes", dBytes];
	} else if(dBytes <= pow(2, 20)) {
		return [NSString stringWithFormat:@"%0.1f KB", dBytes / pow(1024, 1)];
	} else if(dBytes <= pow(2, 30)) {
		return [NSString stringWithFormat:@"%0.1f MB", dBytes / pow(1024, 2)];
	} else if(dBytes <= pow(2, 40)) {
		return [NSString stringWithFormat:@"%0.1f GB", dBytes / pow(1024, 3)];
	} else {
		return [NSString stringWithFormat:@"%0.1f TB", dBytes / pow(1024, 4)];
	}
}

@end
