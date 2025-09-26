//
//  HelpOverlayViewController.m
//  xFonts
//
//  Created by manolo on 9/20/25.
//  Copyright © 2025 manolo. All rights reserved.
//

#import "HelpOverlayViewController.h"

@interface HelpOverlayViewController ()

@property (nonatomic, weak) IBOutlet UIButton *okButton;

@end

@implementation HelpOverlayViewController

- (void)viewDidLoad {
    [super viewDidLoad];
	
	if (@available(iOS 26.0, *)) {
		[self.okButton setConfiguration:UIButtonConfiguration.prominentGlassButtonConfiguration];
	}
}

@end
