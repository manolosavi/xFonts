//
//  AppDelegate.m
//  xFonts
//
//  Created by manolo on 2/1/17.
//  Copyright © 2017 manolo. All rights reserved.
//

#import "AppDelegate.h"

@interface AppDelegate () {
	UIBackgroundTaskIdentifier bgTask;
}


@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
	if ([launchOptions objectForKey:UIApplicationLaunchOptionsURLKey]) {
		NSURL *url = [launchOptions objectForKey:UIApplicationLaunchOptionsURLKey];
		[self saveFontWithURL:url];
	}
	return true;
}

- (void)applicationWillResignActive:(UIApplication *)application {
	
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
	NSAssert(self->bgTask == UIBackgroundTaskInvalid, nil);
	
	bgTask = [application beginBackgroundTaskWithExpirationHandler: ^{
		dispatch_async(dispatch_get_main_queue(), ^{
			[application endBackgroundTask:self->bgTask];
			self->bgTask = UIBackgroundTaskInvalid;
		});
	}];
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
	[application endBackgroundTask:self->bgTask];
	self->bgTask = UIBackgroundTaskInvalid;
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
	[[NSNotificationCenter defaultCenter] postNotificationName:@"reloadFonts" object:nil];
}

- (void)applicationWillTerminate:(UIApplication *)application {
	
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
	[self saveFontWithURL:url];
	return true;
}

- (void)saveFontWithURL:(NSURL*)url {
	if (url != nil) {
		NSData *urlData = [NSData dataWithContentsOfURL:url];
		[urlData writeToFile:[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, true).firstObject stringByAppendingPathComponent:url.lastPathComponent] atomically:true];
		[[NSNotificationCenter defaultCenter] postNotificationName:@"reloadFonts" object:nil];
	}
}

@end
