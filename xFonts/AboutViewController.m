//
//  AboutViewController.m
//  xFonts
//
//  Created by Craig Hockenberry on 4/19/20.
//  Copyright © 2020 manolo. All rights reserved.
//

#import "AboutViewController.h"

@interface AboutViewController ()

@property (nonatomic, weak) IBOutlet UILabel *productNameLabel;
@property (nonatomic, weak) IBOutlet UILabel *versionLabel;

@end

@implementation AboutViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

	
	NSString *productVersion = [NSBundle.mainBundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
	NSString *productBuild = [NSBundle.mainBundle objectForInfoDictionaryKey:@"CFBundleVersion"];
	self.versionLabel.text = [NSString stringWithFormat:@"VERSION %@ (%@)", productVersion, productBuild];
	
	NSString *productName = [NSString stringWithFormat:@" %@ ", [NSBundle.mainBundle objectForInfoDictionaryKey:@"CFBundleDisplayName"]];
	self.productNameLabel.text = productName;

}

- (IBAction)openIconfactory:(id)sender
{
	[UIApplication.sharedApplication openURL:[NSURL URLWithString:@"https://iconfactory.com"] options:@{} completionHandler:nil];
}

@end
