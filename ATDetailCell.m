// AppTapp Installer
// Copyright 2007 Nullriver, Inc.

#import "ATDetailCell.h"


@implementation ATDetailCell

- (id)init {
	if((self = [super init])) {
		_subtitle = [[NSString alloc] init];
	}

	return self;
}

- (void)dealloc {
	[_subtitle release];

	[super dealloc];
}

- (void)setSubtitle:(NSString *)subtitle {
	[subtitle retain];
	[_subtitle release];
	_subtitle = subtitle;
}
	
- (void)drawTitleInRect:(struct CGRect)fp8 selected:(BOOL)isSelected {
	// Title
	UITextLabel * title = [[[UITextLabel alloc] initWithFrame:CGRectMake(0.0, 0.0f, fp8.size.width, 20.0f)] autorelease];
	UITextLabel * subtitle = [[[UITextLabel alloc] initWithFrame:CGRectMake(0.0f, 0.0f, fp8.size.width, 20.0f)] autorelease];

	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();

	float black[] = { 0.0f, 0.0f, 0.0f, 1.0f };
	float grey[] = { 0.5f, 0.5f, 0.5f, 1.0f };
	float white[] = { 1.0f, 1.0f, 1.0f, 1.0f };

	if(isSelected) {
		[title setColor:CGColorCreate(colorSpace, white)];
		[subtitle setColor:CGColorCreate(colorSpace, white)];
	} else {
		[title setColor:CGColorCreate(colorSpace, black)];
		[subtitle setColor:CGColorCreate(colorSpace, grey)];
	}

	CGColorSpaceRelease(colorSpace);

	// Draw title
	fp8.origin.x = 50.0f;
	fp8.size.width -= 50.0f;
	fp8.origin.y = 9.0f;
	fp8.size.height = 20.0f;
	[title setFont:_font];
	[title setText:_title];
	[title drawContentsInRect:fp8];

	// Draw subtitle
	fp8.origin.y = 29.0f;
	fp8.size.height = 20.0f;
	[subtitle setText:_subtitle];
	[subtitle drawContentsInRect:fp8];
}

@end
