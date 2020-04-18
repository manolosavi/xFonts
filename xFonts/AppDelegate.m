//
//  AppDelegate.m
//  xFonts
//
//  Created by manolo on 2/1/17.
//  Copyright © 2017 manolo. All rights reserved.
//

#import "AppDelegate.h"

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
//	Called when xFonts is opened via the "Copy to xFonts" option in another app and it's being opened for the first time
//	if ([launchOptions objectForKey:UIApplicationLaunchOptionsURLKey]) {
//		NSURL *url = [launchOptions objectForKey:UIApplicationLaunchOptionsURLKey];
//		[self saveFontWithURL:url];
//	}
	return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
	
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
}

- (void)applicationWillTerminate:(UIApplication *)application {	
}

//- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
////	Called when xFonts is opened via the "Copy to xFonts" option in another app and it was already open
//	[self saveFontWithURL:url];
//	return true;
//}

/**
 Copies the font from the url received into the Documents directory

 @param url NSURL to the font file
 */
//- (void)saveFontWithURL:(NSURL*)url {
//	if (url != nil) {
//		NSData *urlData = [NSData dataWithContentsOfURL:url];
//		[urlData writeToFile:[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, true).firstObject stringByAppendingPathComponent:url.lastPathComponent] atomically:true];
//		[[NSNotificationCenter defaultCenter] postNotificationName:@"reloadFonts" object:nil];
//	}
//}

@end
