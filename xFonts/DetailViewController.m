//
//  DetailViewController.m
//  xFonts
//
//  Created by Craig Hockenberry on 4/18/20.
//  Copyright © 2020 manolo. All rights reserved.
//

#import "DetailViewController.h"

@interface DetailViewController ()

@property (nonatomic, weak) IBOutlet UILabel *fileNameLabel;
@property (nonatomic, weak) IBOutlet UILabel *postScriptNameLabel;
@property (nonatomic, weak) IBOutlet UILabel *displayNameLabel;
@property (nonatomic, weak) IBOutlet UILabel *familyNameLabel;
@property (nonatomic, weak) IBOutlet UILabel *styleNameLabel;
@property (nonatomic, weak) IBOutlet UILabel *monospacedLabel;
@property (nonatomic, weak) IBOutlet UILabel *versionNameLabel;
@property (nonatomic, weak) IBOutlet UILabel *glyphCountLabel;
@property (nonatomic, weak) IBOutlet UILabel *copyrightLabel;
@property (nonatomic, weak) IBOutlet UILabel *descriptionLabel;


@property (nonatomic, weak) IBOutlet UIView *versionView;
@property (nonatomic, weak) IBOutlet UIView *copyrightView;
@property (nonatomic, weak) IBOutlet UIView *descriptionView;

@property (nonatomic, weak) IBOutlet UIView *installWarningView;
@property (nonatomic, weak) IBOutlet UIView *sampleBackgroundView;
@property (nonatomic, weak) IBOutlet UITextView *sampleTextView;

@end

@implementation DetailViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	[self updateView];
}

#pragma mark - Utility

- (void)updateView
{
	self.fileNameLabel.text = self.fontInfo.fileName;
	self.postScriptNameLabel.text = self.fontInfo.postScriptName;
	self.displayNameLabel.text = self.fontInfo.displayName;
	self.familyNameLabel.text = self.fontInfo.familyName;
	self.styleNameLabel.text = self.fontInfo.styleName;

	self.monospacedLabel.text = (self.fontInfo.isMonospaced ? @"Yes" : @"No");

	self.glyphCountLabel.text = [NSNumberFormatter localizedStringFromNumber:@(self.fontInfo.numberOfGlyphs) numberStyle:NSNumberFormatterDecimalStyle];
	if (self.fontInfo.versionName) {
		self.versionNameLabel.text = self.fontInfo.versionName;
	}
	else {
		self.versionView.hidden = YES;
	}
	if (self.fontInfo.copyrightName) {
		self.copyrightLabel.text = self.fontInfo.copyrightName;
	}
	else {
		self.copyrightView.hidden = YES;
	}
	if (self.fontInfo.descriptionName) {
		self.descriptionLabel.text = self.fontInfo.descriptionName;
	}
	else {
		self.descriptionView.hidden = YES;
	}
		
	if (self.fontInfo.isInstalled) {
		UIFont *font = [UIFont fontWithName:self.fontInfo.postScriptName size:32.0];
		self.sampleTextView.font = font;
		self.sampleTextView.textColor = UIColor.labelColor;
		self.sampleTextView.text = @"ABCDEFGHIJKLM\nNOPQRSTUVWXYZ\nabcdefghijklm\nnopqrstuvwxyz\n0123456789-+=\n!@#$%&*{(’”?;\n\nHamburgfonstiv\n\nHow razorback-jumping frogs can level six piqued gymnasts!";
	}
	else {
		self.sampleTextView.font = [UIFont systemFontOfSize:32.0];
		self.sampleTextView.textColor = UIColor.secondaryLabelColor;
		self.sampleTextView.text = @"\nA sample will be displayed here when the font is installed.\n";
	}
	self.sampleBackgroundView.layer.cornerRadius = 4.0;
	
	self.installWarningView.hidden = self.fontInfo.isInstalled;
	self.installWarningView.layer.cornerRadius = 4.0;
}

@end
