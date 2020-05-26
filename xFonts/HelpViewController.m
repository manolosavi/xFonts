//
//  HelpViewController.m
//  xFonts
//
//  Created by Craig Hockenberry on 4/22/20.
//  Copyright © 2020 manolo. All rights reserved.
//

#import "HelpViewController.h"

#import "NSAttributedString+Markdown.h"

#import "DebugLog.h"


@interface HelpViewController ()

@property (nonatomic, weak) IBOutlet UITextView *textView;

@end

@implementation HelpViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

	self.textView.linkTextAttributes = @{ NSForegroundColorAttributeName: [UIColor colorNamed:@"appTint"], NSUnderlineStyleAttributeName: @(1) };
	self.textView.textContainerInset = UIEdgeInsetsMake(20, 15, 20, 15);

	[self loadHelpMarkdown];
	
	[self.textView scrollRangeToVisible:NSMakeRange(0, 0)];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection
{
	DebugLog(@"%s called", __PRETTY_FUNCTION__);
	if (previousTraitCollection.preferredContentSizeCategory != self.traitCollection.preferredContentSizeCategory) {
		[self loadHelpMarkdown];
	}
}

#pragma mark - Utility

- (void)loadHelpMarkdown
{
	NSString *productName = [NSBundle.mainBundle objectForInfoDictionaryKey:@"CFBundleDisplayName"];

	NSURL *markdownURL = [NSBundle.mainBundle URLForResource:@"Help" withExtension:@"md"];
	NSData *markdownData = [NSData dataWithContentsOfURL:markdownURL];
	NSString *markdownString = [[NSString alloc] initWithData:markdownData encoding:NSUTF8StringEncoding];
	NSAssert(markdownString != nil, @"Missing help Markdown text");
	
	markdownString = [markdownString stringByReplacingOccurrencesOfString:@"$(PRODUCT_NAME)" withString:productName];

	UIColor *bodyTextColor = UIColor.secondaryLabelColor;
	UIColor *emphasisColor = UIColor.labelColor;
	UIColor *highlightColor = [UIColor colorNamed:@"appTint"];

	UIFont *baseFont = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];

	UIFont *emphasisBaseFont = [UIFont systemFontOfSize:baseFont.pointSize weight:UIFontWeightMedium];
	UIFontDescriptor *emphasisSingleFontDescriptor = [emphasisBaseFont.fontDescriptor fontDescriptorWithSymbolicTraits:(UIFontDescriptorTraitItalic | UIFontDescriptorTraitBold)];
	
	UIFont *emphasisSingleFont = [UIFont fontWithDescriptor:emphasisSingleFontDescriptor size:baseFont.pointSize];
	UIFont *emphasisDoubleFont = emphasisBaseFont;
	UIFont *emphasisBothFont = [UIFont systemFontOfSize:baseFont.pointSize weight:UIFontWeightHeavy];
	
	NSDictionary<MarkdownStyleKey, NSDictionary<NSAttributedStringKey, id> *> *styleAttributes = @{
		MarkdownStyleEmphasisSingle: @{
				NSFontAttributeName: emphasisSingleFont,
				NSForegroundColorAttributeName: emphasisColor
		},
		MarkdownStyleEmphasisDouble: @{
				NSFontAttributeName: emphasisDoubleFont,
				NSForegroundColorAttributeName: emphasisColor
		},
		MarkdownStyleEmphasisBoth: @{
				NSFontAttributeName: emphasisBothFont,
				NSForegroundColorAttributeName: highlightColor
		},
	};
	
	NSDictionary<NSAttributedStringKey,id> *attributes = @{ NSFontAttributeName: baseFont, NSForegroundColorAttributeName: bodyTextColor };

	NSAttributedString *attributedString = [[NSAttributedString alloc] initWithMarkdownRepresentation:markdownString baseAttributes:attributes styleAttributes:styleAttributes];
	self.textView.attributedText = attributedString;
}

@end
