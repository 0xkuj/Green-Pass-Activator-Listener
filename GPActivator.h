#include "GreenPass.h"
#import <libactivator/libactivator.h>

@interface GPActivator : NSObject <LAListener>
+(void)load;
-(void)activator:(LAActivator *)activator receiveEvent:(LAEvent *)event;
@end

