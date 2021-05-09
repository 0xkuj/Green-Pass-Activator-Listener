#include "GPSRootListController.h"
#import <spawn.h>

@interface UIApplication ()
-(BOOL)launchApplicationWithIdentifier:(id)arg1 suspended:(BOOL)arg2 ;
@end


@implementation GPSRootListController

- (NSArray *)specifiers {
	if (!_specifiers) {
		_specifiers = [self loadSpecifiersFromPlistName:@"Root" target:self];
	}

	return _specifiers;
}
/* read values from preferences */
- (id)readPreferenceValue:(PSSpecifier*)specifier {
	NSString *path = [NSString stringWithFormat:@"/User/Library/Preferences/%@.plist", specifier.properties[@"defaults"]];
	NSMutableDictionary *settings = [NSMutableDictionary dictionary];
	[settings addEntriesFromDictionary:[NSDictionary dictionaryWithContentsOfFile:path]];
	return (settings[specifier.properties[@"key"]]) ?: specifier.properties[@"default"];
}

/* set the value immediately when needed */
- (void)setPreferenceValue:(id)value specifier:(PSSpecifier*)specifier {
	NSString *path = [NSString stringWithFormat:@"/User/Library/Preferences/%@.plist", specifier.properties[@"defaults"]];
	NSMutableDictionary *settings = [NSMutableDictionary dictionary];
	[settings addEntriesFromDictionary:[NSDictionary dictionaryWithContentsOfFile:path]];
	[settings setObject:value forKey:specifier.properties[@"key"]];
	[settings writeToFile:path atomically:YES];
	CFStringRef notificationName = (__bridge CFStringRef)specifier.properties[@"PostNotification"];
	if (notificationName) {
		CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), notificationName, NULL, NULL, YES);
	}
}

/* default settings and repsring right after. files to be deleted are specified in this function */
-(void)defaultsettings:(PSSpecifier*)specifier {
	#define GREEN_PASS_PLIST @"/var/mobile/Library/Preferences/com.0xkuj.greenpassprefs.plist"
	UIAlertController* alertController = [UIAlertController alertControllerWithTitle:@"Confirmation"
    									                    message:@"This will restore Green Pass Settings to default\nAre you sure?" 
    														preferredStyle:UIAlertControllerStyleAlert];
	/* prepare function for "yes" button */
	UIAlertAction* OKAction = [UIAlertAction actionWithTitle:@"Yes" style:UIAlertActionStyleDefault
    		handler:^(UIAlertAction * action) {
				[[NSFileManager defaultManager] removeItemAtURL: [NSURL fileURLWithPath:GREEN_PASS_PLIST] error: nil];
    			[self reload];
    			CFNotificationCenterRef r = CFNotificationCenterGetDarwinNotifyCenter();
    			CFNotificationCenterPostNotification(r, (CFStringRef)@"com.0xkuj.greenpassprefs.settingschanged", NULL, NULL, true);
				UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Notice"
				message:@"Settings restored to default\nPlease respring your device" 
				preferredStyle:UIAlertControllerStyleAlert];
				UIAlertAction* DoneAction =  [UIAlertAction actionWithTitle:@"Respring" style:UIAlertActionStyleDefault
    			handler:^(UIAlertAction * action) {
					pid_t pid;
					const char* args[] = {"killall", "backboardd", NULL};
					posix_spawn(&pid, "/usr/bin/killall", NULL, NULL, (char* const*)args, NULL);
				}];
				[alert addAction:DoneAction];
				[self presentViewController:alert animated:YES completion:nil];
	}];
	/* prepare function for "no" button" */
	UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"No" style: UIAlertActionStyleCancel handler:^(UIAlertAction * action) { return; }];
	/* actually assign those actions to the buttons */
	[alertController addAction:OKAction];
    [alertController addAction:cancelAction];
	/* present the dialog and wait for an answer */
	[self presentViewController:alertController animated:YES completion:nil];
	return;
}

- (void)respring:(id)sender {
	UIAlertController* alertController = [UIAlertController alertControllerWithTitle:@"Respring"
    									                    message:@"Are you sure?" 
    														preferredStyle:UIAlertControllerStyleAlert];
	/* prepare function for "yes" button */
	UIAlertAction* OKAction = [UIAlertAction actionWithTitle:@"Yes" style:UIAlertActionStyleDefault
    		handler:^(UIAlertAction * action) {
			pid_t pid;
			const char* args[] = {"killall", "backboardd", NULL};
			posix_spawn(&pid, "/usr/bin/killall", NULL, NULL, (char* const*)args, NULL);
	}];
	/* prepare function for "no" button" */
	UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"No" style: UIAlertActionStyleCancel handler:^(UIAlertAction * action) { return; }];
	/* actually assign those actions to the buttons */
	[alertController addAction:OKAction];
    [alertController addAction:cancelAction];
	/* present the dialog and wait for an answer */
	[self presentViewController:alertController animated:YES completion:nil];
}

/* iOS 13 deprecated these functions */

-(void)openTwitter {
	UIApplication *application = [UIApplication sharedApplication];
	NSURL *URL = [NSURL URLWithString:@"https://www.twitter.com/omrkujman"];
	[application openURL:URL options:@{} completionHandler:^(BOOL success) {return;}];
}

-(void)donationLink {
	UIApplication *application = [UIApplication sharedApplication];
	NSURL *URL = [NSURL URLWithString:@"https://www.paypal.me/0xkuj"];
	[application openURL:URL options:@{} completionHandler:^(BOOL success) {return;}];
}

-(void)openActivator {
	[[UIApplication sharedApplication] launchApplicationWithIdentifier:@"libactivator" suspended:NO];
}

@end
