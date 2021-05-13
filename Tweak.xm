/* v1.0 This tweak allows you to pick a favorite photo and display it anywhere on your device using activator gesture */
/* features in the future: multiple photos selection, video support, draggin/resizing the imageview. add cancel animations, and hide swap button.*/
#include "GreenPass.h"
@interface SpringBoard
-(void)GPActivatorAction;
@end


BOOL isEnabled = FALSE;


/* Load preferences after change or after respring */
static void loadPrefs() {
	NSMutableDictionary* mainPreferenceDict = [[NSMutableDictionary alloc] initWithContentsOfFile:GREEN_PASS_PLIST];
	isEnabled = [mainPreferenceDict objectForKey:@"isEnabled"] ? [[mainPreferenceDict objectForKey:@"isEnabled"] boolValue] : YES;
	tweakPrefs.isShowButton = [mainPreferenceDict objectForKey:@"isShowButton"] ? [[mainPreferenceDict objectForKey:@"isShowButton"] boolValue] : YES;
	tweakPrefs.isAnimations = [mainPreferenceDict objectForKey:@"isAnimations"] ? [[mainPreferenceDict objectForKey:@"isAnimations"] boolValue] : YES;
	tweakPrefs.isLongPressOnPic = [mainPreferenceDict objectForKey:@"isLongPressOnPic"] ? [[mainPreferenceDict objectForKey:@"isLongPressOnPic"] boolValue] : NO;
}

%hook SpringBoard
GreenPass *greenPassSharedInstance = nil;
- (void)applicationDidFinishLaunching:(id)application {
	%orig;
	if (!isEnabled)
		return;

	//Signup to activator first time after springboard loads
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(GPActivatorAction) name:@"com.0xkuj.greenpass" object:nil];
	
}

%new
-(void)GPActivatorAction {
	if (!isEnabled)
		return;

	greenPassSharedInstance = [GreenPass sharedInstance];
	//this means there was an error loading the components. maybe add reference to settings and not just fail. or at least display a message.
	if ([greenPassSharedInstance loadComponents] < 0)
	{
		return;
	}
	[greenPassSharedInstance showWindow];
}
%end



%ctor {
	loadPrefs();
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback)loadPrefs, CFSTR("com.0xkuj.greenpassprefs.settingschanged"), NULL, CFNotificationSuspensionBehaviorCoalesce);
}