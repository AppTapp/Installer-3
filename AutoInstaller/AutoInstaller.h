#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <UIKit/UIApplication.h>
#import <UIKit/UIView.h>
#import <UIKit/UIWindow.h>
#import <UIKit/UIProgressBar.h>
#import <UIKit/UITextLabel.h>

#import "ATPackageManager.h"

@interface AutoInstaller : UIApplication
{
	UIWindow* 			mWindow;
	UIView*				mContentView;
	
	UIProgressBar*		mProgressBar;
	UITextLabel*		mProgressCaption;
	
	ATPackageManager*	mPM;
	
	BOOL				mQueueFinished;
}

- (CGRect)centeredRectWithSize:(CGSize)size origin:(CGPoint)origin;

- (NSMutableDictionary*)localSource;
- (NSMutableArray*)localSourcePackages;

@end

#define NSLocalizedStringWithValue(key, val) \
	    [[NSBundle mainBundle] localizedStringForKey:(key) value:(val) table:nil]
