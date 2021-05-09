/* v1.0 This tweak allows you to pick a favorite photo and display it anywhere on your device using activator gesture */
/* features in the future: multiple photos selection, video support, draggin/resizing the imageview */
#import "GPActivator.h"
@interface SpringBoard
-(void)windowForPrompts;
-(void)fadeBlurAndView:(id)sender;
-(UIImage*) scaleImage:(UIImage*)image toSize:(CGSize)newSize;
@end

@interface NSUserDefaults ()
-(id)objectForKey:(id)arg1 inDomain:(id)arg2 ;
@end

BOOL isEnabled = FALSE;

/* Load preferences after change or after respring */
static void loadPrefs() {
	#define GREEN_PASS_PLIST @"/var/mobile/Library/Preferences/com.0xkuj.greenpassprefs.plist"
	NSMutableDictionary* mainPreferenceDict = [[NSMutableDictionary alloc] initWithContentsOfFile:GREEN_PASS_PLIST];
	isEnabled = [mainPreferenceDict objectForKey:@"isEnabled"] ? [[mainPreferenceDict objectForKey:@"isEnabled"] boolValue] : YES;
}

%hook SpringBoard
UIWindow* _alertWindow;
UIImageView* gpMainImageView;
- (void)applicationDidFinishLaunching:(id)application {
	%orig;
	if (!isEnabled)
		return;

	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(activatorGP) name:@"com.0xkuj.greenpass" object:nil];
}

%new
-(void)activatorGP {
	if (!isEnabled)
		return;

	NSString* const imagesDomain = @"com.0xkuj.greenpassprefs";
	NSData* data = [[NSUserDefaults standardUserDefaults] objectForKey:@"backgroundImage" inDomain:imagesDomain];
	if (data == nil) {
		NSLog(@"No image was assigned!");
		return;
	}
	UIImage* bgImage = [UIImage imageWithData:data];
	UIImage* imageResized = [self scaleImage:bgImage toSize:CGSizeMake([[UIScreen mainScreen] bounds].size.width-30, [[UIScreen mainScreen] bounds].size.height-30)];
	gpMainImageView = [[UIImageView alloc] initWithImage:imageResized];
	[self windowForPrompts];
}

%new
- (UIImage*)scaleImage:(UIImage*)image toSize:(CGSize)newSize {

    CGSize imageSize = image.size;
    CGFloat newWidth  = newSize.width  / image.size.width;
    CGFloat newHeight = newSize.height / image.size.height;
    CGSize newImgSize;

    if(newWidth > newHeight) {
        newImgSize = CGSizeMake(imageSize.width * newHeight, imageSize.height * newHeight);
    } else {
        newImgSize = CGSizeMake(imageSize.width * newWidth,  imageSize.height * newWidth);
    }

    CGRect rect = CGRectMake(0, 0, newImgSize.width, newImgSize.height);
    UIGraphicsBeginImageContextWithOptions(newImgSize, false, 0.0);
    [image drawInRect:rect];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return newImage;
}

%new
-(void)windowForPrompts {
	_alertWindow= [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    _alertWindow.rootViewController = [UIViewController new];
    _alertWindow.windowLevel = UIWindowLevelAlert+1;
    _alertWindow.hidden = NO;
    _alertWindow.tintColor = [[UIWindow valueForKey:@"keyWindow"] tintColor];
	gpMainImageView.alpha = 0;
	gpMainImageView.clipsToBounds = YES;
	gpMainImageView.layer.cornerRadius = 15.0f;
	gpMainImageView.frame = CGRectMake((_alertWindow.rootViewController.view.frame.size.width / 2) - (gpMainImageView.image.size.width / 2), (_alertWindow.rootViewController.view.frame.size.height / 2) - (gpMainImageView.image.size.height / 2), gpMainImageView.image.size.width, gpMainImageView.image.size.height);
	[_alertWindow.rootViewController.view addSubview:gpMainImageView];
	[UIView animateWithDuration:0.3f
    	animations:^{
				[UIView animateWithDuration:0.3f
                      delay:0.0
                    options:UIViewAnimationCurveLinear
                 animations:^{
					gpMainImageView.alpha = 1;
               } completion:NULL];
    	} completion:^(BOOL finished) { 	}
	];
	UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(fadeBlurAndView:)];
	[_alertWindow addGestureRecognizer:tapGestureRecognizer];
}

%new
- (void)fadeBlurAndView:(id)sender 
{
	[UIView animateWithDuration:0.3f
    	animations:^{
				[UIView animateWithDuration:0.3f
                      delay:0.0
                    options:UIViewAnimationCurveLinear
                 animations:^{
					gpMainImageView.alpha = 0;
               } completion:NULL];
    	} completion:^(BOOL finished) { 	}
	];	
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.3 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
		_alertWindow = nil;
	});
	 
}
%end

%ctor {
	loadPrefs();
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback)loadPrefs, CFSTR("com.0xkuj.greenpassprefs.settingschanged"), NULL, CFNotificationSuspensionBehaviorCoalesce);
}