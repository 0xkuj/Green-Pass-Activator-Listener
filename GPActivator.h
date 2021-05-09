
#import <libactivator/libactivator.h>

@interface GPActivator : NSObject <LAListener>
@end

@implementation GPActivator
+(void)load {
	[[NSClassFromString(@"LAActivator") sharedInstance] registerListener:[self new] forName:@"com.0xkuj.greenpass"];
}

-(void)activator:(LAActivator *)activator receiveEvent:(LAEvent *)event {
    [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:@"com.0xkuj.greenpass" object:self userInfo:nil]];
}
@end
