/* v1.0 This tweak allows you to pick a favorite photo and display it anywhere on your device using activator gesture */
/* features in the future: multiple photos selection, video support, draggin/resizing the imageview */
#import "GPActivator.h"
@interface SpringBoard
-(void)windowForPrompts;
-(void)fadeBlurAndView:(id)sender;
-(UIImage*) scaleImage:(UIImage*)image toSize:(CGSize)newSize;
//-(void)moveImageWithGesture:(UIPanGestureRecognizer *)panGesture;
//- (void)pinchGestureDidFire:(UIPinchGestureRecognizer *)pinch;
- (void)moveImage:(UIPanGestureRecognizer *)panRecognizer;
- (void)rotateImage:(UIRotationGestureRecognizer *)rotationGestureRecognizer;
- (void)pinchImage:(UIPinchGestureRecognizer *)pinchRecognizer;
-(void)buttonPressedAction:(id)sender;
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info;
-(void)activatorGP;
@end
float globalLeftX = 0, globalRightX = 0, globalUpperY = 0, globalLowerY = 0;
UIButton *button;
@interface NSUserDefaults ()
-(id)objectForKey:(id)arg1 inDomain:(id)arg2 ;
@end

/* created for recognizing touches in view inside the window holding it */
@interface WindowTouchRecognizerSubview : UIWindow
@end

@implementation WindowTouchRecognizerSubview
- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
	//touched in view or in button
	NSLog(@"omriku button: x: %f, y: %f", button.frame.origin.x, button.frame.origin.y);
	if ((point.x > globalLeftX && point.x < globalRightX && point.y > globalUpperY && point.y < globalLowerY)
	    || (point.x > button.frame.origin.x && point.x < button.frame.origin.x + 45 && point.y > button.frame.origin.y && point.y < button.frame.origin.y+45) ) {
		return YES;
	}
    else {
		return NO;
	}
}
@end

BOOL isEnabled = FALSE;
#define GREEN_PASS_PLIST @"/var/mobile/Library/Preferences/com.0xkuj.greenpassprefs.plist"
/* Load preferences after change or after respring */
static void loadPrefs() {

	NSMutableDictionary* mainPreferenceDict = [[NSMutableDictionary alloc] initWithContentsOfFile:GREEN_PASS_PLIST];
	isEnabled = [mainPreferenceDict objectForKey:@"isEnabled"] ? [[mainPreferenceDict objectForKey:@"isEnabled"] boolValue] : YES;
}
static void updateGlobalCords(float leftx, float rightx,float upy,float lowy) {
	#define INITIAL_IMAGE_OFFSET 15
	globalLeftX = leftx+INITIAL_IMAGE_OFFSET;
	globalRightX = rightx+INITIAL_IMAGE_OFFSET;
	globalUpperY = upy+INITIAL_IMAGE_OFFSET;
	globalLowerY = lowy+INITIAL_IMAGE_OFFSET;
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
	//make this a class that init with imageview?
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
	_alertWindow= [[WindowTouchRecognizerSubview alloc] initWithFrame:[UIScreen mainScreen].bounds];
    _alertWindow.rootViewController = [UIViewController new];
    _alertWindow.windowLevel = UIWindowLevelAlert+1;
    _alertWindow.hidden = NO;
    _alertWindow.tintColor = [[WindowTouchRecognizerSubview valueForKey:@"keyWindow"] tintColor];
	// ########button start
	button = [UIButton buttonWithType:UIButtonTypeCustom];
	//[button setTitle:@"NA" forState:UIControlStateNormal];
	[button addTarget:self  action:@selector(buttonPressedAction:) forControlEvents:UIControlEventTouchUpInside];
	button.frame = CGRectMake(0,0, 45,45);
	button.center = _alertWindow.rootViewController.view.center;
	button.frame = CGRectMake(button.frame.origin.x,_alertWindow.rootViewController.view.frame.size.height - 100, 45,45);
	button.alpha = 0;
	// ########### button end
	//button.frame = CGRectMake(300, 300, 45, 45);
	UIImage* swapIcon = [self scaleImage:[UIImage imageNamed:@"/Library/PreferenceBundles/GreenPassPrefs.bundle/swapiconalt.png"] toSize:CGSizeMake(45,45)];
    [button setImage:swapIcon forState:UIControlStateNormal];
	//need to fix the coordinates here as well. this is why they button is pressable only when inside the view
	

	gpMainImageView.alpha = 0;
	
	gpMainImageView.clipsToBounds = YES;
	gpMainImageView.layer.cornerRadius = 15.0f;
	gpMainImageView.frame = CGRectMake((_alertWindow.rootViewController.view.frame.size.width / 2) - (gpMainImageView.image.size.width / 2), (_alertWindow.rootViewController.view.frame.size.height / 2) - (gpMainImageView.image.size.height / 2), gpMainImageView.image.size.width, gpMainImageView.image.size.height);
	[_alertWindow.rootViewController.view addSubview:gpMainImageView];
	[_alertWindow.rootViewController.view addSubview:button];
	[UIView animateWithDuration:0.3f
    	animations:^{
				[UIView animateWithDuration:0.3f
                      delay:0.0
                    options:UIViewAnimationCurveLinear
                 animations:^{
					gpMainImageView.alpha = 1;
					button.alpha = 1;
               } completion:NULL];
    	} completion:^(BOOL finished) { 	}
	];
	UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(fadeBlurAndView:)];
	gpMainImageView.userInteractionEnabled = YES;
	[gpMainImageView addGestureRecognizer:tapGestureRecognizer];

	UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(moveImage:)];
	UIRotationGestureRecognizer *rotationGesture = [[UIRotationGestureRecognizer alloc] initWithTarget:self action:@selector(rotateImage:)];
	UIPinchGestureRecognizer *pinchGesture = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(pinchImage:)];

	[gpMainImageView addGestureRecognizer:panGesture];
	[gpMainImageView addGestureRecognizer:rotationGesture];
	[gpMainImageView addGestureRecognizer:pinchGesture];
	updateGlobalCords(gpMainImageView.frame.origin.x,gpMainImageView.frame.origin.x + gpMainImageView.frame.size.width,
						gpMainImageView.frame.origin.y, gpMainImageView.frame.origin.y + gpMainImageView.frame.size.height);

}

//this works. need to add lock on the lockscreen so it wont turn off.
%new
/* Main contact button is pressed. will launch according to the settings the user chose */
-(void)buttonPressedAction:(id)sender {    
	NSLog(@"omriku pressed a button");
	UIImagePickerController* imagePicker = [[UIImagePickerController alloc ] init];
	//[imagePicker _setAllowsMultipleSelection:TRUE];
	// Check if image access is authorized
	if([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
		imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
		// Use delegate methods to get result of photo library -- Look up UIImagePicker delegate methods
		imagePicker.delegate = (id)self;
		[_alertWindow.rootViewController presentViewController:imagePicker animated:YES completion:nil];
	}	
}
%new
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
	NSLog(@"omriku image controller.");
	UIImage *pickedImage = info[UIImagePickerControllerOriginalImage];
	NSData *dataToStore = [NSData dataWithData:UIImageJPEGRepresentation(pickedImage,1.0)];	
	NSLog(@"omriku image controller data %@",dataToStore);
	NSUserDefaults* prefs = [[NSUserDefaults alloc] initWithSuiteName:GREEN_PASS_PLIST];
	[prefs setObject:dataToStore forKey:@"backgroundImage"];	
    [[NSUserDefaults standardUserDefaults] synchronize];
	[picker dismissViewControllerAnimated:YES completion:nil];
	[self activatorGP];
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
					button.alpha = 0;
               } completion:NULL];
    	} completion:^(BOOL finished) { 	}
	];	
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.3 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
		_alertWindow = nil;
	});
	 
}

%new
- (void)pinchImage:(UIPinchGestureRecognizer *)pinchRecognizer
{
    UIGestureRecognizerState state = [pinchRecognizer state];

    if (state == UIGestureRecognizerStateBegan || state == UIGestureRecognizerStateChanged)
    {
        CGFloat scale = [pinchRecognizer scale];
        [pinchRecognizer.view setTransform:CGAffineTransformScale(pinchRecognizer.view.transform, scale, scale)];
        [pinchRecognizer setScale:1.0];
    }
	updateGlobalCords(pinchRecognizer.view.frame.origin.x,pinchRecognizer.view.frame.origin.x + pinchRecognizer.view.frame.size.width,
						pinchRecognizer.view.frame.origin.y, pinchRecognizer.view.frame.origin.y + pinchRecognizer.view.frame.size.height);
}

%new
- (void)rotateImage:(UIRotationGestureRecognizer *)rotationGestureRecognizer {

    UIGestureRecognizerState state = [rotationGestureRecognizer state];

    if (state == UIGestureRecognizerStateBegan || state == UIGestureRecognizerStateChanged)
    {
        CGFloat rotation = [rotationGestureRecognizer rotation];
        [rotationGestureRecognizer.view setTransform:CGAffineTransformRotate(rotationGestureRecognizer.view.transform, rotation)];
        [rotationGestureRecognizer setRotation:0];
    }
		updateGlobalCords(rotationGestureRecognizer.view.frame.origin.x,rotationGestureRecognizer.view.frame.origin.x + rotationGestureRecognizer.view.frame.size.width,
						rotationGestureRecognizer.view.frame.origin.y, rotationGestureRecognizer.view.frame.origin.y + rotationGestureRecognizer.view.frame.size.height);
}

%new
- (void)moveImage:(UIPanGestureRecognizer *)panRecognizer {

    UIGestureRecognizerState state = [panRecognizer state];

    if (state == UIGestureRecognizerStateBegan || state == UIGestureRecognizerStateChanged)
    {
        CGPoint translation = [panRecognizer translationInView:panRecognizer.view];
        [panRecognizer.view setTransform:CGAffineTransformTranslate(panRecognizer.view.transform, translation.x, translation.y)];
        [panRecognizer setTranslation:CGPointZero inView:panRecognizer.view];
    }
	updateGlobalCords(panRecognizer.view.frame.origin.x, panRecognizer.view.frame.origin.x + panRecognizer.view.frame.size.width,
						panRecognizer.view.frame.origin.y,panRecognizer.view.frame.origin.y + panRecognizer.view.frame.size.height);
}
%end



%ctor {
	loadPrefs();
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback)loadPrefs, CFSTR("com.0xkuj.greenpassprefs.settingschanged"), NULL, CFNotificationSuspensionBehaviorCoalesce);
}