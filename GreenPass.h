

#define GREEN_PASS_PLIST @"/var/mobile/Library/Preferences/com.0xkuj.greenpassprefs.plist"
#define GREEN_PASS_ASSETS_SWAP_ICON @"/Library/PreferenceBundles/GreenPassPrefs.bundle/swapiconalt.png"

struct viewPreferences {
   BOOL isShowButton;
   BOOL isAnimations;
   BOOL isLongPressOnPic;
} tweakPrefs;

@interface NSUserDefaults ()
-(id)objectForKey:(id)arg1 inDomain:(id)arg2 ;
@end

@interface NSObject (PrivateFLEXall)
-(id)safeValueForKey:(id)arg1;
@end

@interface SBDashBoardIdleTimerProvider : NSObject
-(void)addDisabledIdleTimerAssertionReason:(id)arg1;
-(void)removeDisabledIdleTimerAssertionReason:(id)arg1;
@end

@interface SBDashBoardViewController : UIViewController {
	SBDashBoardIdleTimerProvider *_idleTimerProvider;
}
@end

@interface SBDashBoardIdleTimerController : NSObject {
	SBDashBoardIdleTimerProvider *_dashBoardIdleTimerProvider;
}
@end

@interface CSCoverSheetViewController : UIViewController
-(id)idleTimerController;
@end

@interface SBCoverSheetPresentationManager : NSObject
+(id)sharedInstance;
-(id)dashBoardViewController;
-(id)coverSheetViewController;
@end

@interface GreenPass : NSObject
+ (id)sharedInstance;
- (int)loadComponents;
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

