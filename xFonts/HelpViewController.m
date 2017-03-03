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
	
	_imageView.layer.opacity = 0;
}

- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
	
	_scrollView.contentOffset = CGPointMake(_scrollView.frame.size.width, 0);
//	Animate the image in from left to right
	[UIView animateWithDuration:0.2 animations:^{
		_scrollView.contentOffset = CGPointZero;
		_imageView.layer.opacity = 1;
	}];
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
	
	[UIView animateWithDuration:0.2 animations:^{
		_imageView.layer.opacity = 0;
	}];
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
