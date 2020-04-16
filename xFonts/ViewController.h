//
//  ViewController.h
//  xFonts
//
//  Created by manolo on 2/1/17.
//  Copyright © 2017 manolo. All rights reserved.
//

@import UIKit;
@import CoreText;

//#import "PresentationBlurAnimator.h"
//#import "DismissBlurAnimator.h"

#import "FontInfo.h"

@interface ViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, UIViewControllerTransitioningDelegate>

@property (nonatomic, weak) IBOutlet UITableView *tableView;
@property (nonatomic, weak) IBOutlet UIBarButtonItem *installButton;
@property (nonatomic, weak) IBOutlet UIBarButtonItem *addButton;

@property (nonatomic, strong) NSArray<FontInfo *> *fonts;

@end
