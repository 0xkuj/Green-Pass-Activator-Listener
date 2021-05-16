#include "GPActivator.h"

@implementation GPActivator
+(void)load {
	[[NSClassFromString(@"LAActivator") sharedInstance] registerListener:[self new] forName:@"com.0xkuj.greenpass"];
}

//add instance code here
-(void)activator:(LAActivator *)activator receiveEvent:(LAEvent *)event {
    [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:@"com.0xkuj.greenpass" object:self userInfo:nil]];
    if (!tweakPrefs.isEnabled)
    {
        return;
    }
    GreenPass *greenPassSharedInstance = [GreenPass sharedInstance];
	//this means there was an error loading the components. maybe add reference to settings and not just fail. or at least display a message.
	if ([greenPassSharedInstance loadComponents] < 0)
	{
		return;
	}
	[greenPassSharedInstance showWindow];

}
@end
