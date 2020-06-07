//
//  DetailViewController.h
//  xFonts
//
//  Created by Craig Hockenberry on 4/18/20.
//  Copyright © 2020 manolo. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "FontInfo.h"

NS_ASSUME_NONNULL_BEGIN

@interface DetailViewController : UIViewController

@property (nonatomic, strong) FontInfo *fontInfo;

@end

NS_ASSUME_NONNULL_END
