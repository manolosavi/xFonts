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

- (void)showHelpOverlay
{
	[self performSegueWithIdentifier:@"helpOverlay" sender:self];
}

- (IBAction)unwindToTabBar:(UIStoryboardSegue *)unwindSegue
{
	[self dismissViewControllerAnimated:YES completion:nil];
}

@end
