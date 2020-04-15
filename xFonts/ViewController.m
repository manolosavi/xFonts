//
//  ViewController.m
//  xFonts
//
//  Created by manolo on 2/1/17.
//  Copyright © 2017 manolo. All rights reserved.
//

#import <SafariServices/SafariServices.h>

#import "ViewController.h"
#import "RoutingHTTPServer.h"

#import "DebugLog.h"

@interface ViewController () <SFSafariViewControllerDelegate, UIDocumentPickerDelegate>

@property (nonatomic, strong) RoutingHTTPServer *http;

@end

@implementation ViewController

- (void)viewDidLoad {
	[super viewDidLoad];
	
//	Set self as observer for the "reloadFonts" notification to reload the TableView data when the application
//	comes back to the foreground or is opened via the "Copy to xFonts" option in another app
//	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loadFonts) name:@"reloadFonts" object:nil];
	
	
	//self.selectedFonts = [NSMutableArray array];
	//self.fullSelection = true;
	
	//[_selectButton setPossibleTitles:[NSSet setWithObjects: @"None", @"All", nil]];
	
	//_noFontsView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"pattern"]];
	
	[self startHTTPServer];
	[self loadFonts];
}

/**
 Ennumerates through all files in the Documents directory to look for fonts to show on the TableView.
 */
- (void)loadFonts {
	NSString *file;
	NSMutableArray *loadedFonts = [NSMutableArray array];
	NSDirectoryEnumerator *dirEnum = [[NSFileManager defaultManager] enumeratorAtPath:[NSHomeDirectory() stringByAppendingPathComponent:@"Documents"]];
	while ((file = [dirEnum nextObject])) {
		NSString *filePath = file;
		NSString *fileName = file.lastPathComponent;
		NSString *fileExtension = fileName.pathExtension;
		
		NSString *fontName = nil;
		if ([fileExtension isEqual:@"otf"]) {
			fontName = [fileName stringByReplacingOccurrencesOfString:@".otf" withString:@""];
		}
		else if ([fileExtension isEqual:@"ttf"]) {
			fontName = [fileName stringByReplacingOccurrencesOfString:@".ttf" withString:@""];
		}
		
		if (fontName) {
			NSString *postscriptName = nil;
			// Registers the font for use, this way we can show each row with its respective font as a preview.
			NSData *fontData = [[NSData alloc] initWithContentsOfURL:[self urlForFile:file]];
			CFErrorRef error;
			CGDataProviderRef providerRef = CGDataProviderCreateWithCFData((CFDataRef)fontData);
			if (providerRef) {
				CGFontRef fontRef = CGFontCreateWithDataProvider(providerRef);
				if (fontRef) {
					if (!CTFontManagerRegisterGraphicsFont(fontRef, &error)) {
						CFStringRef errorDescription = CFErrorCopyDescription(error);
						if (CFErrorGetCode(error) != 105) {
							ReleaseLog(@"%s Failed to load font: %@", __PRETTY_FUNCTION__, errorDescription);
						}
						CFRelease(errorDescription);
					}
					else {
						postscriptName = (NSString *)CFBridgingRelease(CGFontCopyPostScriptName(fontRef));
					}
					CFRelease(fontRef);
				}
				CFRelease(providerRef);
			}
			
			FontInfo *fontInfo = [FontInfo new];
			fontInfo.filePath = filePath;
			fontInfo.postscriptName = postscriptName;
			fontInfo.displayName = fontName;
			
			[loadedFonts addObject:fontInfo];
		}
	}
	self.fonts = [loadedFonts copy];
	
	[_tableView reloadData];
}

- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];
}

#pragma mark - Actions

- (IBAction)openInstallProfilePage:(id)sender {
	[self saveFontsProfile:^{
		NSURL *URL = [NSURL URLWithString:[NSString stringWithFormat:@"http://localhost:3333/"]];
		
		SFSafariViewController *viewController = [[SFSafariViewController alloc] initWithURL:URL];
		viewController.delegate = self;
		[self presentViewController:viewController animated:YES completion:^{
			// TODO: something here?
		}];
		//[[UIApplication sharedApplication] openURL:URL options:@{} completionHandler:nil];
	}];
}

- (IBAction)addFonts:(id)sender {
	NSArray<NSString *> *allowedUTIs = @[ @"public.truetype-font" , @"public.opentype-font"];
	UIDocumentPickerViewController *viewController = [[UIDocumentPickerViewController alloc] initWithDocumentTypes:allowedUTIs inMode:UIDocumentPickerModeImport];
	viewController.allowsMultipleSelection = YES;
	viewController.delegate = self;
	
	[self presentViewController:viewController animated:YES completion:^{
		// TODO: something here?
	}];
}

/**
 Called when the TableView reloads, depending on the shouldShow parameter, the noFontsView will be added or removed.

 @param shouldShow true when the TableView is empty
 */
//- (void)showNoFontsView:(BOOL)shouldShow {
//	if (shouldShow) {
//		_tableView.hidden = true;
//		_installButton.enabled = false;
//		_selectButton.enabled = false;
//		[self.view addSubview:_noFontsView];
//		_noFontsView.translatesAutoresizingMaskIntoConstraints = false;
//		
////		Constraints to make noFontsView the same size as it's superview
//		NSLayoutConstraint *centerX = [NSLayoutConstraint constraintWithItem:_noFontsView attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:_noFontsView.superview attribute:NSLayoutAttributeCenterX multiplier:1 constant:0];
//		NSLayoutConstraint *centerY = [NSLayoutConstraint constraintWithItem:_noFontsView attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:_noFontsView.superview attribute:NSLayoutAttributeCenterY multiplier:1 constant:0];
//		NSLayoutConstraint *widthConstraint = [NSLayoutConstraint constraintWithItem:_noFontsView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:_noFontsView.superview attribute:NSLayoutAttributeWidth multiplier:1 constant:0];
//		NSLayoutConstraint *heightConstraint = [NSLayoutConstraint constraintWithItem:_noFontsView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:_noFontsView.superview attribute:NSLayoutAttributeHeight multiplier:1 constant:0];
//		[_noFontsView.superview addConstraints:@[centerX, centerY, widthConstraint, heightConstraint]];
//		
//	} else {
//		_tableView.hidden = false;
//		[_noFontsView removeFromSuperview];
//	}
//}

#pragma mark - UITableView Delegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	//[self showNoFontsView:_allFonts.count == 0];
	return self.fonts.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
	
	FontInfo *fontInfo = self.fonts[indexPath.row];
	
	cell.textLabel.text = fontInfo.displayName;
	cell.textLabel.font = [UIFont fontWithName:fontInfo.postscriptName size:16];
	
	UIView *selection = [UIView new];
	selection.backgroundColor = [UIColor colorWithHue:260/360.0 saturation:0.5 brightness:0.8 alpha:1];
	cell.selectedBackgroundView = selection;
	
	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
	return true;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
	if (editingStyle == UITableViewCellEditingStyleDelete) {
		UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:@"Delete Font" message:@"Are you sure you want to delete this font? This cannot be undone." preferredStyle:UIAlertControllerStyleAlert];
		alertVC.view.tintColor = self.view.tintColor;
		
		// Show alert to warn about the deletion of the font. Delete the font if the user confirms.
		UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
		UIAlertAction *deleteAction = [UIAlertAction actionWithTitle:@"Delete" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
			FontInfo *fontInfo = self.fonts[indexPath.row];
			if ([self removeFile:fontInfo.filePath]) {
				NSMutableArray *newFonts = [self.fonts mutableCopy];
				[newFonts removeObjectAtIndex:indexPath.row];
				self.fonts = [newFonts copy];
				
				[tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
			}
		}];
		
		[alertVC addAction:cancelAction];
		[alertVC addAction:deleteAction];
		
		[self presentViewController:alertVC animated:true completion:nil];
	}
}

/**
 Starts the HTTP Server and sets the response to the root directory to allow the install of profiles.
 */
- (void)startHTTPServer {
	self.http = [RoutingHTTPServer new];
	[self.http setPort:3333];
	[self.http setDefaultHeader:@"Content-Type" value:@"application/x-apple-aspen-config"];
	[self.http setDocumentRoot:[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, true) objectAtIndex:0]];
	
	[self.http handleMethod:@"GET" withPath:@"/" block:^(RouteRequest *request, RouteResponse *response) {
//		This is what the server will respond with when going to the root directory.
		[response setHeader:@"Content-Type" value:@"text/html"];
		
//		Get the html file from the main bundle, send it as the response string.
		NSString *path = [[NSBundle mainBundle] pathForResource:@"index" ofType:@"html"];
		NSString *html = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
		
		[response respondWithString:html];
	}];
	
	[self.http start:nil];
}


/**
 Goes through the list of fonts and adds all the selected ones to the profile, then saves the completed profile to the Documents directory.

 @param completion this block is called when the profile has completed saving to disk
 */
- (void)saveFontsProfile:(void(^)(void))completion {
	NSInteger count = 0;
	NSString *fonts = @"";
	for (int i=0; i<self.fonts.count; i++) {
		FontInfo *fontInfo = self.fonts[i];

		NSURL *url = [self urlForFile:fontInfo.filePath];
		
		NSString *UUIDString = NSUUID.UUID.UUIDString;
		NSString *font = [[[NSData alloc] initWithContentsOfURL:url] base64EncodedStringWithOptions:NSDataBase64EncodingEndLineWithLineFeed];
		
		fonts = [fonts stringByAppendingString:[NSString stringWithFormat:@"<dict><key>PayloadType</key><string>com.apple.font</string><key>PayloadVersion</key><integer>1</integer><key>PayloadIdentifier</key><string>%@</string><key>PayloadUUID</key><string>%@</string><key>Name</key><string>%@</string><key>Font</key><data>%@</data></dict>", fontInfo.displayName, UUIDString, fontInfo.displayName, font]];
		
		count++;
	}
	NSString *title = [NSString stringWithFormat:@"%ld font%@", (long)count, (count>1?@"s":@"")];
	
	NSString *profile = [NSString stringWithFormat:@"<?xml version=\"1.0\" encoding=\"UTF-8\"?><!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\"><plist version=\"1.0\"><dict><key>PayloadType</key><string>Configuration</string><key>PayloadVersion</key><integer>1</integer><key>PayloadDisplayName</key><string>xFonts (%@)</string><key>PayloadIdentifier</key><string>xFonts %@</string><key>PayloadUUID</key><string>%@</string><key>PayloadContent</key><array>%@</array></dict></plist>", title, NSUUID.UUID.UUIDString, NSUUID.UUID.UUIDString, fonts];
	
	[self saveString:profile toFile:@"/xFonts.mobileconfig"];
	completion();
}

/**
 Returns an NSURL [in Documents directory] for the file passed on the parameter.

 @param fileName whose NSURL you need
 @return NSURL to the file
 */
- (NSURL*)urlForFile:(NSString*)fileName {
	NSURL *directory = [[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask].firstObject;
	return [directory URLByAppendingPathComponent:fileName];
}

/**
 Returns an NSString with the path [in Documents directory] for the file passed on the parameter.

 @param fileName whose path you need
 @return path to the file
 */
- (NSString*)pathForFile:(NSString*)fileName {
	NSString *filePath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, true).firstObject;
	return [filePath stringByAppendingString:fileName];
}

/**
 Saves the string "str" to disk on the "fileName" path.

 @param str file to save as a string
 @param fileName path to where the file should be saved
 */
- (void)saveString:(NSString*)str toFile:(NSString*)fileName {
	NSString *fileAtPath = [self pathForFile:fileName];
	if (![[NSFileManager defaultManager] fileExistsAtPath:fileAtPath]) {
		[[NSFileManager defaultManager] createFileAtPath:fileAtPath contents:nil attributes:nil];
	}
	[[str dataUsingEncoding:NSUTF8StringEncoding] writeToFile:fileAtPath atomically:true];
}

/**
 Removes the file at the "fileName" path.

 @param fileName path to file you want to delete
 @return true if the file was deleted, false if it couldn't be deleted
 */
- (BOOL)removeFile:(NSString*)fileName {
	if (![[fileName substringWithRange:NSMakeRange(0, 1)] isEqualToString:@"/"]) {
		fileName = [@"/" stringByAppendingString:fileName];
	}
	NSString *fileAtPath = [self pathForFile:fileName];
	
	NSError *error;
	if (![[NSFileManager defaultManager] removeItemAtPath:fileAtPath error:&error]) {
		ReleaseLog(@"%s Could not delete file: %@", __PRETTY_FUNCTION__, [error localizedDescription]);
		return false;
	}
	return true;
}

#pragma mark - Navigation

//- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
//	if ([segue.identifier isEqualToString:@"HelpSegue"]) {
//		UIViewController *vc = segue.destinationViewController;
////		Set the transitioning delegate to allow for the custom animators
//		vc.transitioningDelegate = self;
//	}
//}

#pragma mark - UIDocumentPickerDelegate

- (void)documentPicker:(UIDocumentPickerViewController *)controller didPickDocumentsAtURLs:(NSArray <NSURL *>*)urls API_AVAILABLE(ios(11.0))
{
	DebugLog(@"%s urls = %@", __PRETTY_FUNCTION__, urls);
}

// called if the user dismisses the document picker without selecting a document (using the Cancel button)
- (void)documentPickerWasCancelled:(UIDocumentPickerViewController *)controller
{
	DebugLog(@"%s called", __PRETTY_FUNCTION__);
}

#pragma mark - SFSafariViewControllerDelegate

- (void)safariViewControllerDidFinish:(SFSafariViewController *)controller
{
	[self dismissViewControllerAnimated:YES completion:^{
		// TODO: something here?
	}];
}

//#pragma mark - Custom Blur Transition
//
//- (id<UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented presentingController:(UIViewController *)presenting sourceController:(UIViewController *)source {
//	return [PresentationBlurAnimator new];
//}
//
//- (id<UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed {
//	return [DismissBlurAnimator new];
//}

@end
