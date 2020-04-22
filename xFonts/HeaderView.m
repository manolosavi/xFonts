//
//  HeaderView.m
//  xFonts
//
//  Created by Craig Hockenberry on 4/22/20.
//  Copyright © 2020 manolo. All rights reserved.
//

#import "HeaderView.h"

@interface HeaderView ()

@property (nonatomic, weak) IBOutlet UILabel *statusLabel;

@end

@implementation HeaderView

- (void)setFontAddedCount:(NSInteger)addedCount installCount:(NSInteger)installCount
{
	if (installCount > 0) {
		self.statusLabel.text = [NSString stringWithFormat:@"%ld font%s added, %ld need%s install", addedCount, (addedCount == 1 ? "" : "s"), installCount, (installCount == 1 ? "s" : "")];
	}
	else {
		self.statusLabel.text = [NSString stringWithFormat:@"%ld fonts added", addedCount];
	}
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection
{
	//DebugLog(@"%s called", __PRETTY_FUNCTION__);
	if (previousTraitCollection.userInterfaceStyle != self.traitCollection.userInterfaceStyle) {
		//[self loadHelpMarkdown];
	}
}

@end
