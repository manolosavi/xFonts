//
//  ViewController.h
//  xFonts
//
//  Created by manolo on 2/1/17.
//  Copyright © 2017 manolo. All rights reserved.
//

@import UIKit;
@import CoreText;

@interface ViewController : UIViewController <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, weak) IBOutlet UITableView *tableView;
@property (nonatomic, weak) IBOutlet UIBarButtonItem *installButton;
@property (nonatomic, weak) IBOutlet UIBarButtonItem *selectButton;


@property (nonatomic, strong) NSArray *allFonts;
@property (nonatomic, strong) NSMutableArray *selectedFonts;

@end
