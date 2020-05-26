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
		self.statusLabel.text = [NSString stringWithFormat:@"%ld font%s imported, %ld need%s installation", addedCount, (addedCount == 1 ? "" : "s"), installCount, (installCount == 1 ? "s" : "")];
	}
	else {
		self.statusLabel.text = [NSString stringWithFormat:@"%ld font%s imported", addedCount, (addedCount == 1 ? "" : "s")];
	}
}

@end
