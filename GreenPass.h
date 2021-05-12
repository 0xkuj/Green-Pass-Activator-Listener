

#define GREEN_PASS_PLIST @"/var/mobile/Library/Preferences/com.0xkuj.greenpassprefs.plist"
#define GREEN_PASS_ASSETS @"/Library/PreferenceBundles/GreenPassPrefs.bundle/swapiconalt.png"

struct viewPreferences {
   BOOL isShowButton;
   BOOL isAnimations;
} tweakPrefs;

@interface NSUserDefaults ()
-(id)objectForKey:(id)arg1 inDomain:(id)arg2 ;
@end

@interface NSObject (PrivateFLEXall)
-(id)safeValueForKey:(id)arg1;
@end

@interface SBDashBoardIdleTimerProvider : NSObject // iOS 11 - 13
-(void)addDisabledIdleTimerAssertionReason:(id)arg1; // iOS 11 - 13
-(void)removeDisabledIdleTimerAssertionReason:(id)arg1; // iOS 11 - 13
// -(BOOL)isDisabledAssertionActiveForReason:(id)arg1; // iOS 11 - 13
// -(void)resetIdleTimer; // iOS 11 - 13
@end

@interface SBDashBoardViewController : UIViewController { // iOS 10 - 12
	SBDashBoardIdleTimerProvider *_idleTimerProvider; // iOS 11 - 12
}
@end

@interface SBDashBoardIdleTimerController : NSObject { // iOS 13
	SBDashBoardIdleTimerProvider *_dashBoardIdleTimerProvider; // iOS 13
}
@end

@interface CSCoverSheetViewController : UIViewController // iOS 13
-(id)idleTimerController; // iOS 13
@end

@interface SBCoverSheetPresentationManager : NSObject // iOS 11 - 13
+(id)sharedInstance; // iOS 11 - 13
-(id)dashBoardViewController; // iOS 11 - 12
-(id)coverSheetViewController; // iOS 13
@end

@interface GreenPass : NSObject
+ (id)sharedInstance;
- (void)loadComponents;
- (void)showWindow;
/* not needed to be declared */
/*
- (UIImage*) scaleImage:(UIImage*)image toSize:(CGSize)newSize;
- (void)moveImage:(UIPanGestureRecognizer *)panRecognizer;
- (void)rotateImage:(UIRotationGestureRecognizer *)rotationGestureRecognizer;
- (void)pinchImage:(UIPinchGestureRecognizer *)pinchRecognizer;
- (void)buttonPressedAction:(id)sender;
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info;
*/
@end

