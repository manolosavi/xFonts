//
//  HelpViewController.m
//  xFonts
//
//  Created by manolo on 2/15/17.
//  Copyright © 2017 manolo. All rights reserved.
//

#import "HelpViewController.h"

@interface HelpViewController ()

@end

@implementation HelpViewController

- (void)viewDidLoad {
	[super viewDidLoad];
}

- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];
}

- (IBAction)didTapBackground:(id)sender {
	[self dismissViewControllerAnimated:true completion:nil];
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {

}

@end
