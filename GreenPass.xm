#include "GreenPass.h"
#import "UIImage+Gif.h"
#define CRITICAL_ERROR -1
#define BUTTON_DIMENSIONS 45

@interface PHImageManager
-(int)requestImageDataForAsset:(id)arg1 options:(id)arg2 resultHandler:(/*^block*/id)arg3 ;
+(id)defaultManager;
@end

@interface PHAsset
+(id)fetchAssetsWithALAssetURLs:(id)arg1 options:(id)arg2 ;
@end

@implementation GPTouchRecognizerWindow
- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
	//touched in view or in button
    GreenPass *greenPassSharedInstance = [GreenPass sharedInstance];
    return [greenPassSharedInstance isTouched:point] ? YES : NO;
}
@end


/* Load preferences after change or after respring */
static void loadPrefs() {
	NSMutableDictionary* mainPreferenceDict = [[NSMutableDictionary alloc] initWithContentsOfFile:GREEN_PASS_PLIST];
	tweakPrefs.isEnabled = [mainPreferenceDict objectForKey:@"isEnabled"] ? [[mainPreferenceDict objectForKey:@"isEnabled"] boolValue] : YES;
	tweakPrefs.isShowButton = [mainPreferenceDict objectForKey:@"isShowButton"] ? [[mainPreferenceDict objectForKey:@"isShowButton"] boolValue] : YES;
	tweakPrefs.isAnimations = [mainPreferenceDict objectForKey:@"isAnimations"] ? [[mainPreferenceDict objectForKey:@"isAnimations"] boolValue] : YES;
	tweakPrefs.isLongPressOnPic = [mainPreferenceDict objectForKey:@"isLongPressOnPic"] ? [[mainPreferenceDict objectForKey:@"isLongPressOnPic"] boolValue] : NO;
}

@implementation GreenPass
__strong static id _sharedObject;
+(id)sharedInstance
{
    if (!_sharedObject) {
        _sharedObject = [[self alloc] init];
    }
    return _sharedObject;
}

- (int)loadComponents {
    if ([self loadImageView] < 0)
    {
        return CRITICAL_ERROR;
    }
    [self loadImageViewGestures];
    if (tweakPrefs.isShowButton) {
        [self loadButton];
    }
    [self loadWindow];
    //means all ok
    return 0;
} 

-(void)loadButton {
	button = [UIButton buttonWithType:UIButtonTypeCustom];
	[button addTarget:self action:@selector(buttonPressedAction) forControlEvents:UIControlEventTouchUpInside];
    UILongPressGestureRecognizer *longPressRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(hideButtonDialog:)];
    longPressRecognizer.minimumPressDuration = 0.3;
    [button addGestureRecognizer:longPressRecognizer];
    //hack button to have the proper center with 0,0 to begins with
	button.frame = CGRectMake(0,0, BUTTON_DIMENSIONS,BUTTON_DIMENSIONS);
	button.center = CGPointMake(([[UIScreen mainScreen] bounds].size.width / 2), ([[UIScreen mainScreen] bounds].size.height / 2));
	button.frame = CGRectMake(button.frame.origin.x,[[UIScreen mainScreen] bounds].size.height - 100, button.frame.size.width,button.frame.size.height);
	UIImage* swapIcon = [self scaleImage:[UIImage imageNamed:GREEN_PASS_ASSETS_SWAP_ICON] toSize:CGSizeMake(BUTTON_DIMENSIONS,BUTTON_DIMENSIONS)];
    [button setImage:swapIcon forState:UIControlStateNormal];
}

//Thanks to wl. from STO
-(BOOL)isGifFromData:(NSData *)data {
    uint8_t c;
    [data getBytes:&c length:1];

    if (c == 0x47) {
        return YES;
    }
    return NO;
}

-(int)loadImageView {
    #define GREEN_PASS_PHOTO_SPACING_FROM_EDGES 30
    #define GREEN_PASS_CORNER_RADIUS 15.0f
    NSString* const imagesDomain = @"com.0xkuj.greenpassprefs";
	NSData* data = [[NSUserDefaults standardUserDefaults] objectForKey:@"backgroundImage" inDomain:imagesDomain];
	if (data == nil) {
		NSLog(@"GreenPass: No image was assigned!");
		return CRITICAL_ERROR;
	}

	UIImage* bgImage = [UIImage gifWithData:data]; 
    /* if this is not a gif, resize. resizing makes the gif goes poof */
    if (![self isGifFromData:data]) {
	    UIImage* imageResized = [self scaleImage:bgImage toSize:CGSizeMake([[UIScreen mainScreen] bounds].size.width - GREEN_PASS_PHOTO_SPACING_FROM_EDGES, [[UIScreen mainScreen] bounds].size.height - GREEN_PASS_PHOTO_SPACING_FROM_EDGES)];
	    self.gpMainImageView = [[UIImageView alloc] initWithImage:imageResized];
    } else {
        self.gpMainImageView = [[UIImageView alloc] initWithImage:bgImage];
    }

	self.gpMainImageView.clipsToBounds = YES;
	self.gpMainImageView.layer.cornerRadius = GREEN_PASS_CORNER_RADIUS;
    //adjust the image frame to the screen
    self.gpMainImageView.frame = CGRectMake(([[UIScreen mainScreen] bounds].size.width / 2) - (self.gpMainImageView.image.size.width / 2), ([[UIScreen mainScreen] bounds].size.height / 2) - (self.gpMainImageView.image.size.height / 2), self.gpMainImageView.image.size.width, self.gpMainImageView.image.size.height);
    //return OK status
    return 0;
}

-(void)loadImageViewGestures {
    self.gpMainImageView.userInteractionEnabled = YES;
	UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(animateFadeAway)];
    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(moveImage:)];
	UIRotationGestureRecognizer *rotationGesture = [[UIRotationGestureRecognizer alloc] initWithTarget:self action:@selector(rotateImage:)];
	UIPinchGestureRecognizer *pinchGesture = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(pinchImage:)];

    if (tweakPrefs.isLongPressOnPic) {
        UILongPressGestureRecognizer *longPressRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(buttonPressedAction)];
        longPressRecognizer.minimumPressDuration = 0.3;
        [self.gpMainImageView addGestureRecognizer:longPressRecognizer];
    }

	[self.gpMainImageView addGestureRecognizer:tapGestureRecognizer];
	[self.gpMainImageView addGestureRecognizer:panGesture];
	[self.gpMainImageView addGestureRecognizer:rotationGesture];
	[self.gpMainImageView addGestureRecognizer:pinchGesture];
}

-(void)loadWindow {
	_alertWindow = [[GPTouchRecognizerWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    _alertWindow.rootViewController = [UIViewController new];
    _alertWindow.windowLevel = UIWindowLevelAlert+1;
    _alertWindow.hidden = NO;
    [_alertWindow _setSecure:YES];
    [_alertWindow setAutorotates:FALSE];
    _alertWindow.tintColor = [[GPTouchRecognizerWindow valueForKey:@"keyWindow"] tintColor];
}

- (void)showWindow {
    //prepare animation alpha
	self.gpMainImageView.alpha = 0;
    button.alpha = 0;
	[_alertWindow.rootViewController.view addSubview:self.gpMainImageView];

    if (tweakPrefs.isShowButton) {
        [_alertWindow.rootViewController.view addSubview:button];
    }
	
    if (tweakPrefs.isAnimations) {
        [UIView animateWithDuration:0.3f
            animations:^{
                    [UIView animateWithDuration:0.3f
                        delay:0.0
                        options:UIViewAnimationOptionCurveEaseIn
                    animations:^{
                        self.gpMainImageView.alpha = 1;
                        button.alpha = 1;
                } completion:NULL];
            } completion:^(BOOL finished) { 	}
        ];
    } else {
        self.gpMainImageView.alpha = 1;
        button.alpha = 1;
    }

	//updateGlobalCords(self.gpMainImageView.frame.origin.x,self.gpMainImageView.frame.origin.x + self.gpMainImageView.frame.size.width,
					//	self.gpMainImageView.frame.origin.y, self.gpMainImageView.frame.origin.y + self.gpMainImageView.frame.size.height);
    [self updateGlobalCords:self.gpMainImageView.frame.origin.x RightX:self.gpMainImageView.frame.origin.x + self.gpMainImageView.frame.size.width
                           UpperY:self.gpMainImageView.frame.origin.y LowerY:self.gpMainImageView.frame.origin.y + self.gpMainImageView.frame.size.height];

}

-(void)hideButtonDialog:(UILongPressGestureRecognizer*)sender {
    //show window only once!
    if (sender.state != UIGestureRecognizerStateBegan) {
        return;
    }
	UIAlertController* alertController = [UIAlertController alertControllerWithTitle:@"Green Pass"
    									                    message:@"Do you wish to temporarily hide the button?" 
    														preferredStyle:UIAlertControllerStyleAlert];
	/* prepare function for "yes" button */
	UIAlertAction* OKAction = [UIAlertAction actionWithTitle:@"Yes, only for now" style:UIAlertActionStyleDefault 
    		handler:^(UIAlertAction * action) {
                    button.alpha = 0;
	}];
    /* prepare function for "yes" button */
	UIAlertAction* keepHiddenAction = [UIAlertAction actionWithTitle:@"Yes, and keep hidden" style:UIAlertActionStyleDefault 
    		handler:^(UIAlertAction * action) {
                NSMutableDictionary *settings = [NSMutableDictionary dictionary];
                [settings addEntriesFromDictionary:[NSDictionary dictionaryWithContentsOfFile:GREEN_PASS_PLIST]];
                [settings setObject:[NSNumber numberWithBool:NO] forKey:@"isShowButton"];
                [settings writeToFile:GREEN_PASS_PLIST atomically:YES];
                tweakPrefs.isShowButton = FALSE;
                button.alpha = 0;
	}];
	/* prepare function for "no" button" */
	UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"No" style: UIAlertActionStyleCancel handler:^(UIAlertAction * action) { return; }];
	/* actually assign those actions to the buttons */
	[alertController addAction:OKAction];
    [alertController addAction:keepHiddenAction];
    [alertController addAction:cancelAction];
	/* present the dialog and wait for an answer */
    UIWindow* tempWindowForPrompt = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    tempWindowForPrompt.rootViewController = [UIViewController new];
    tempWindowForPrompt.windowLevel = UIWindowLevelAlert+1;
    tempWindowForPrompt.hidden = NO;
    tempWindowForPrompt.tintColor = [[UIWindow valueForKey:@"keyWindow"] tintColor];
    [tempWindowForPrompt.rootViewController presentViewController:alertController animated:YES completion:nil];
}
//this works. need to add lock on the lockscreen so it wont turn off.
- (void)buttonPressedAction {    

	UIImagePickerController* imagePicker = [[UIImagePickerController alloc ] init];
	//[imagePicker _setAllowsMultipleSelection:TRUE];
	// Check if image access is authorized
	if([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
		imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
		imagePicker.delegate = (id)self;
        [GetDashBoardIdleTimerProvider() addDisabledIdleTimerAssertionReason:@"GP"];   
		[_alertWindow.rootViewController presentViewController:imagePicker animated:YES completion:nil];
	}	
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [GetDashBoardIdleTimerProvider() removeDisabledIdleTimerAssertionReason:@"GP"];
    [picker dismissViewControllerAnimated:YES completion:nil];
}

/* we get here only when a pic was selected */
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    //get our new image 
    NSURL* refURL = [info objectForKey:@"UIImagePickerControllerReferenceURL"];
    if (refURL) {
        PHAsset* asset = [[PHAsset fetchAssetsWithALAssetURLs:@[refURL] options:nil] lastObject];
		if (asset)
		{
			//user chose an image
			[[PHImageManager defaultManager] requestImageDataForAsset:asset options:nil resultHandler:^(NSData * _Nullable data, NSString * _Nullable dataUTI, UIImageOrientation orientation, NSDictionary * _Nullable info)
			{
				if (data)
				{
                        NSUserDefaults* prefs = [[NSUserDefaults alloc] initWithSuiteName:GREEN_PASS_PLIST];
                        [prefs setObject:data forKey:@"backgroundImage"];	
                        [[NSUserDefaults standardUserDefaults] synchronize];
					}
				}];
        }
    }
    [GetDashBoardIdleTimerProvider() removeDisabledIdleTimerAssertionReason:@"GP"];
    [picker dismissViewControllerAnimated:YES completion:nil];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.3 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            //load our components and show new photo
            [self loadComponents];
            [self showWindow];
	});	 

    
}

- (void)animateFadeAway
{
    if (tweakPrefs.isAnimations) {
        [UIView animateWithDuration:0.3f
            animations:^{
                    [UIView animateWithDuration:0.3f
                        delay:0.0
                        options:UIViewAnimationOptionCurveEaseIn
                    animations:^{
                        self.gpMainImageView.alpha = 0;
                        button.alpha = 0;
                } completion:NULL];
            } completion:^(BOOL finished) {}
        ];	
    } else {
        self.gpMainImageView.alpha = 0;
        button.alpha = 0;
    }
    //we dont need this but just to be safe..   
    [GetDashBoardIdleTimerProvider() removeDisabledIdleTimerAssertionReason:@"GP"];
    //kill window after done
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.3 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        if (_alertWindow) {
		    _alertWindow = nil;
        }
	});	 
}

- (void)pinchImage:(UIPinchGestureRecognizer *)pinchRecognizer
{
    [GetDashBoardIdleTimerProvider() addDisabledIdleTimerAssertionReason:@"GP"];   

    UIGestureRecognizerState state = [pinchRecognizer state];
    if (state == UIGestureRecognizerStateBegan || state == UIGestureRecognizerStateChanged)
    {
        CGFloat scale = [pinchRecognizer scale];
        [pinchRecognizer.view setTransform:CGAffineTransformScale(pinchRecognizer.view.transform, scale, scale)];
        [pinchRecognizer setScale:1.0];
    }
	//updateGlobalCords(pinchRecognizer.view.frame.origin.x,pinchRecognizer.view.frame.origin.x + pinchRecognizer.view.frame.size.width,
					//	pinchRecognizer.view.frame.origin.y, pinchRecognizer.view.frame.origin.y + pinchRecognizer.view.frame.size.height);

    [self updateGlobalCords:pinchRecognizer.view.frame.origin.x RightX:pinchRecognizer.view.frame.origin.x + pinchRecognizer.view.frame.size.width
                           UpperY:pinchRecognizer.view.frame.origin.y LowerY:pinchRecognizer.view.frame.origin.y + pinchRecognizer.view.frame.size.height];
    [GetDashBoardIdleTimerProvider() removeDisabledIdleTimerAssertionReason:@"GP"];
}

- (void)rotateImage:(UIRotationGestureRecognizer *)rotationGestureRecognizer {

    [GetDashBoardIdleTimerProvider() addDisabledIdleTimerAssertionReason:@"GP"];

    UIGestureRecognizerState state = [rotationGestureRecognizer state];

    if (state == UIGestureRecognizerStateBegan || state == UIGestureRecognizerStateChanged)
    {
        CGFloat rotation = [rotationGestureRecognizer rotation];
        [rotationGestureRecognizer.view setTransform:CGAffineTransformRotate(rotationGestureRecognizer.view.transform, rotation)];
        [rotationGestureRecognizer setRotation:0];
    }
	//updateGlobalCords(rotationGestureRecognizer.view.frame.origin.x,rotationGestureRecognizer.view.frame.origin.x + rotationGestureRecognizer.view.frame.size.width,
				//		rotationGestureRecognizer.view.frame.origin.y, rotationGestureRecognizer.view.frame.origin.y + rotationGestureRecognizer.view.frame.size.height);

    [self updateGlobalCords:rotationGestureRecognizer.view.frame.origin.x RightX:rotationGestureRecognizer.view.frame.origin.x + rotationGestureRecognizer.view.frame.size.width
                           UpperY:rotationGestureRecognizer.view.frame.origin.y LowerY:rotationGestureRecognizer.view.frame.origin.y + rotationGestureRecognizer.view.frame.size.height];
    [GetDashBoardIdleTimerProvider() removeDisabledIdleTimerAssertionReason:@"GP"];                     
}


- (void)moveImage:(UIPanGestureRecognizer *)panRecognizer {

    [GetDashBoardIdleTimerProvider() addDisabledIdleTimerAssertionReason:@"GP"];
    UIGestureRecognizerState state = [panRecognizer state];

    if (state == UIGestureRecognizerStateBegan || state == UIGestureRecognizerStateChanged)
    {
        CGPoint translation = [panRecognizer translationInView:panRecognizer.view];
        [panRecognizer.view setTransform:CGAffineTransformTranslate(panRecognizer.view.transform, translation.x, translation.y)];
        [panRecognizer setTranslation:CGPointZero inView:panRecognizer.view];
    }
	//updateGlobalCords(panRecognizer.view.frame.origin.x, panRecognizer.view.frame.origin.x + panRecognizer.view.frame.size.width,
						//panRecognizer.view.frame.origin.y,panRecognizer.view.frame.origin.y + panRecognizer.view.frame.size.height);

    [self updateGlobalCords:panRecognizer.view.frame.origin.x RightX:panRecognizer.view.frame.origin.x + panRecognizer.view.frame.size.width
                           UpperY:panRecognizer.view.frame.origin.y LowerY:panRecognizer.view.frame.origin.y + panRecognizer.view.frame.size.height];

    [GetDashBoardIdleTimerProvider() removeDisabledIdleTimerAssertionReason:@"GP"];                     
}

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


-(void)updateGlobalCords:(float)leftx RightX:(float)rightx UpperY:(float)upy LowerY:(float)lowy {
	#define INITIAL_IMAGE_OFFSET 15
	leftXView = leftx+INITIAL_IMAGE_OFFSET;
	rigthXView = rightx+INITIAL_IMAGE_OFFSET;
	uppperYView = upy+INITIAL_IMAGE_OFFSET;
	lowerYView = lowy+INITIAL_IMAGE_OFFSET;
}

-(BOOL)isViewTouched:(CGPoint)point {
    return (point.x > leftXView && point.x < rigthXView && point.y > uppperYView && point.y < lowerYView);
}
-(BOOL)isButtonTouched:(CGPoint)point {
    return (point.x > button.frame.origin.x && point.x < button.frame.origin.x + BUTTON_DIMENSIONS 
             && point.y > button.frame.origin.y && point.y < button.frame.origin.y + BUTTON_DIMENSIONS);
}

-(BOOL)isTouched:(CGPoint)point {
    return ([self isViewTouched:point] || [self isButtonTouched:point]);
}
/* this function will help us keep the screen awake while playing around with the contacts */
static SBDashBoardIdleTimerProvider* GetDashBoardIdleTimerProvider() {
	SBCoverSheetPresentationManager *presentationManager = [NSClassFromString(@"SBCoverSheetPresentationManager") sharedInstance];
	SBDashBoardIdleTimerProvider *_idleTimerProvider = nil;
	if ([presentationManager respondsToSelector:@selector(dashBoardViewController)]) {
		SBDashBoardViewController *dashBoardViewController = [presentationManager dashBoardViewController];
		_idleTimerProvider = [dashBoardViewController safeValueForKey:@"_idleTimerProvider"];
	} else if ([presentationManager respondsToSelector:@selector(coverSheetViewController)]) {
		SBDashBoardIdleTimerController *dashboardIdleTimerController = [[presentationManager coverSheetViewController] idleTimerController];
		_idleTimerProvider = [dashboardIdleTimerController safeValueForKey:@"_dashBoardIdleTimerProvider"];
	}
	return _idleTimerProvider;
}

@end


//this loads up when your dylib gets injected thanks to the filter, he knows where to inject!
%ctor {
	loadPrefs();
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback)loadPrefs, CFSTR("com.0xkuj.greenpassprefs.settingschanged"), NULL, CFNotificationSuspensionBehaviorCoalesce);
}