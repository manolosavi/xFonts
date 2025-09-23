//
//  TabBarController.m
//  xFonts
//
//  Created by Craig Hockenberry on 4/19/20.
//  Copyright © 2020 manolo. All rights reserved.
//

#import "TabBarController.h"

@interface TabBarController ()

@end

@implementation TabBarController

- (void)viewDidLoad
{
	// NOTE: This is needed to set the color of the tab bar on iPadOS.
	// https://developer.apple.com/forums/thread/759337?answerId=795009022#795009022
	
	UIColor *tabTintColor = [UIColor colorNamed:@"appTint"];
	self.view.tintColor = tabTintColor;
}

- (void)showHelpOverlay
{
	[self performSegueWithIdentifier:@"helpOverlay" sender:self];
}

- (IBAction)unwindToTabBar:(UIStoryboardSegue *)unwindSegue
{
	[self dismissViewControllerAnimated:YES completion:nil];
}

@end
