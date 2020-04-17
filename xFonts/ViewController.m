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

- (void)dealloc {
	
}

- (void)viewDidLoad {
	[super viewDidLoad];
	
//	Set self as observer for the "reloadFonts" notification to reload the TableView data when the application
//	comes back to the foreground or is opened via the "Copy to xFonts" option in another app
//	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loadFonts) name:@"reloadFonts" object:nil];
	
	
	//self.selectedFonts = [NSMutableArray array];
	//self.fullSelection = true;
	
	//[_selectButton setPossibleTitles:[NSSet setWithObjects: @"None", @"All", nil]];
	
	//_noFontsView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"pattern"]];
	[NSNotificationCenter.defaultCenter addObserver:self selector:@selector(applicationDidEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
	
	[self loadFonts];
}

// TODO: add importFonts to copy files from Documents/Inbox to top-level folder if they don't already exist

/**
 Ennumerates through all files in the Documents directory to look for fonts to show on the TableView.
 */
- (void)loadFonts {
//	NSString *file;
	NSMutableArray *loadedFonts = [NSMutableArray array];
//	NSDirectoryEnumerator *dirEnum = [[NSFileManager defaultManager] enumeratorAtPath:[NSHomeDirectory() stringByAppendingPathComponent:@"Documents"]];
//	while ((file = [dirEnum nextObject])) {
	NSError *error = nil;
	NSArray<NSURL *> *URLs = [NSFileManager.defaultManager contentsOfDirectoryAtURL:FontInfo.storageURL includingPropertiesForKeys:nil options:(NSDirectoryEnumerationSkipsSubdirectoryDescendants) error:&error];
	if (! URLs) {
		ReleaseLog(@"%s error = %@", __PRETTY_FUNCTION__, error);
	}
	else {
		for (NSURL *URL in URLs) {
			NSString *fileName = URL.lastPathComponent;
			NSString *fileExtension = fileName.pathExtension;
			
			NSString *fontName = nil;
			if ([fileExtension isEqual:@"otf"]) {
				fontName = [fileName stringByReplacingOccurrencesOfString:@".otf" withString:@""];
			}
			else if ([fileExtension isEqual:@"ttf"]) {
				fontName = [fileName stringByReplacingOccurrencesOfString:@".ttf" withString:@""];
			}
			
			if (fontName) {
				CFErrorRef errorRef;
				if (! CTFontManagerRegisterFontsForURL((CFURLRef)URL, kCTFontManagerScopeProcess, &errorRef)) {
					if (CFErrorGetCode(errorRef) != kCTFontManagerErrorAlreadyRegistered) {
						CFStringRef errorDescription = CFErrorCopyDescription(errorRef);
						ReleaseLog(@"%s Failed to register font: %@", __PRETTY_FUNCTION__, errorDescription);
						CFRelease(errorDescription);
					}
				}
				
				NSString *postscriptName = nil;
				NSString *displayName = nil;
				NSString *copyrightName = nil;
				// Registers the font for use, this way we can show each row with its respective font as a preview.
//				NSData *fontData = [[NSData alloc] initWithContentsOfURL:[self urlForFile:filePath]];
				NSData *fontData = [[NSData alloc] initWithContentsOfURL:URL];
				if (fontData) {
					CGDataProviderRef providerRef = CGDataProviderCreateWithCFData((CFDataRef)fontData);
					if (providerRef) {
						CGFontRef fontRef = CGFontCreateWithDataProvider(providerRef);
						if (fontRef) {
							postscriptName = CFBridgingRelease(CGFontCopyPostScriptName(fontRef));
							displayName = CFBridgingRelease(CGFontCopyFullName(fontRef));
							
							// Also:
							//	CG_EXTERN size_t CGFontGetNumberOfGlyphs(CGFontRef cg_nullable font)
							// kCTFontDescriptionNameKey
							// https://stackoverflow.com/questions/53359789/get-meta-info-from-uifont-or-cgfont-ios-swift
							CTFontRef textFontRef = CTFontCreateWithGraphicsFont(fontRef, 0, NULL, NULL);
							if (textFontRef) {
								copyrightName = CFBridgingRelease(CTFontCopyName(textFontRef, kCTFontCopyrightNameKey));
								
								CFRelease(textFontRef);
								CFRelease(fontRef);
							}
							else {
								ReleaseLog(@"%s no fontRef", __PRETTY_FUNCTION__);
							}
							CFRelease(providerRef);
						}
					}
					else {
						ReleaseLog(@"%s no providerRef", __PRETTY_FUNCTION__);
					}

					DebugLog(@"%s URL = %@, displayName = '%@', postscriptName = '%@', copyrightName = %@", __PRETTY_FUNCTION__, URL, displayName, postscriptName, copyrightName);
					FontInfo *fontInfo = [[FontInfo alloc] initWithFileURL:URL];
					[loadedFonts addObject:fontInfo];
				}
			}
		}
		
		[loadedFonts sortUsingComparator:^NSComparisonResult(FontInfo *fontInfo1, FontInfo *fontInfo2) {
			return [fontInfo1.displayName compare:fontInfo2.displayName];
		}];
		
		self.fonts = [loadedFonts copy];
		
		[self.tableView reloadData];
	}
}

- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];
}

#pragma mark - Actions

- (IBAction)installProfile:(id)sender {
	[self saveFontsProfile:^(NSError *error) {
		if (error) {
			NSString *message = [NSString stringWithFormat:@"The mobile configuration profile could not be created.\n\nThe error was '%@'", error.localizedDescription];
			UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Install Error" message:message preferredStyle:UIAlertControllerStyleAlert];
			alertController.view.tintColor = self.view.tintColor;
			[alertController addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil]];
			
			[self presentViewController:alertController animated:YES completion:nil];
		}
		else {
			[self startHTTPServer];
			
			NSURL *URL = [NSURL URLWithString:[NSString stringWithFormat:@"http://localhost:3333/"]];

			SFSafariViewController *viewController = [[SFSafariViewController alloc] initWithURL:URL];
			viewController.delegate = self;
			viewController.preferredControlTintColor = self.view.tintColor;
			viewController.modalPresentationStyle = UIModalPresentationPageSheet;
			[self presentViewController:viewController animated:YES completion:^{
				// TODO: something here?
			}];
			//[[UIApplication sharedApplication] openURL:URL options:@{} completionHandler:nil];
		}
	}];
}

- (IBAction)addFonts:(id)sender {
	NSArray<NSString *> *allowedUTIs = @[ @"public.truetype-font" , @"public.opentype-font"];
	UIDocumentPickerViewController *viewController = [[UIDocumentPickerViewController alloc] initWithDocumentTypes:allowedUTIs inMode:UIDocumentPickerModeImport];
	viewController.view.tintColor = self.view.tintColor;
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

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	//[self showNoFontsView:_allFonts.count == 0];
	return self.fonts.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
	
	cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	
	FontInfo *fontInfo = self.fonts[indexPath.row];
	
	cell.textLabel.text = fontInfo.displayName;
	cell.textLabel.font = [UIFont fontWithName:fontInfo.postscriptName size:16];

	UIView *selection = [UIView new];
	selection.backgroundColor = [UIColor colorWithHue:260/360.0 saturation:0.5 brightness:0.8 alpha:1];
	cell.selectedBackgroundView = selection;
	
	return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
	return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
	if (editingStyle == UITableViewCellEditingStyleDelete) {
		UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Delete Font" message:@"Are you sure you want to delete this font? There is no undo." preferredStyle:UIAlertControllerStyleAlert];
		alertController.view.tintColor = self.view.tintColor;
		
		// Show alert to warn about the deletion of the font. Delete the font if the user confirms.
		UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
		UIAlertAction *deleteAction = [UIAlertAction actionWithTitle:@"Delete" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
			FontInfo *fontInfo = self.fonts[indexPath.row];
			if ([fontInfo removeFile]) {
				NSMutableArray *newFonts = [self.fonts mutableCopy];
				[newFonts removeObjectAtIndex:indexPath.row];
				self.fonts = [newFonts copy];
				
				[tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
			}
		}];
		
		[alertController addAction:cancelAction];
		[alertController addAction:deleteAction];
		
		[self presentViewController:alertController animated:YES completion:nil];
	}
}

#pragma mark - Utility

/**
 Starts the HTTP Server and sets the response to the root directory to allow the install of profiles.
 */
- (void)startHTTPServer {
	self.http = [RoutingHTTPServer new];
	[self.http setPort:3333];
	[self.http setDefaultHeader:@"Content-Type" value:@"application/x-apple-aspen-config"];
	[self.http setDocumentRoot:[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0]];
	
	[self.http handleMethod:@"GET" withPath:@"/" block:^(RouteRequest *request, RouteResponse *response) {
		// This is what the server will respond with when going to the root directory.
		[response setHeader:@"Content-Type" value:@"text/html"];
		
		// Get the html file from the main bundle, send it as the response string.
		NSString *path = [[NSBundle mainBundle] pathForResource:@"index" ofType:@"html"];
		NSString *html = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
		
		[response respondWithString:html];
	}];
	
	[self.http start:nil];
}

- (void)stopHTTPServer {
	[self.http stop];
}

static NSString *const profilePayloadTemplate =
@"<?xml version=\"1.0\" encoding=\"UTF-8\"?>"
"<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">"
"<plist version=\"1.0\">"
"<dict>"
"<key>PayloadType</key>"
"<string>Configuration</string>"
"<key>PayloadVersion</key>"
"<integer>1</integer>"
"<key>PayloadDisplayName</key>"
"<string>xFonts (%@)</string>"
"<key>PayloadIdentifier</key>"
"<string>xFonts %@</string>"
"<key>PayloadUUID</key>"
"<string>%@</string>"
"<key>PayloadContent</key>"
"<array>%@</array>"
"</dict>"
"</plist>";

static NSString *const fontPayloadTemplate =
	@"<dict>\n"
	"	<key>PayloadType</key>\n"
	"	<string>com.apple.font</string>\n"
	"	<key>PayloadVersion</key>\n"
	"	<integer>1</integer>\n"
	"	<key>PayloadIdentifier</key>\n"
	"	<string>%@</string>\n"
	"	<key>PayloadUUID</key>\n"
	"	<string>%@</string>\n"
	"	<key>Name</key>\n"
	"	<string>%@</string>\n"
	"	<key>Font</key>\n"
	"	<data>%@</data>\n"
	"</dict>";

/**
 Goes through the list of fonts and adds all the selected ones to the profile, then saves the completed profile to the Documents directory.

 @param completion this block is called when the profile has completed saving to disk
 */
- (void)saveFontsProfile:(void(^)(NSError *error))completion {
	NSInteger count = 0;
	NSString *fonts = @"";
	for (int i=0; i<self.fonts.count; i++) {
		FontInfo *fontInfo = self.fonts[i];

		//NSURL *url = [self urlForFile:fontInfo.filePath];
		
		NSString *UUIDString = NSUUID.UUID.UUIDString;
		NSString *font = [[[NSData alloc] initWithContentsOfURL:fontInfo.fileURL] base64EncodedStringWithOptions:NSDataBase64EncodingEndLineWithLineFeed];
		
		fonts = [fonts stringByAppendingString:[NSString stringWithFormat:@"<dict><key>PayloadType</key><string>com.apple.font</string><key>PayloadVersion</key><integer>1</integer><key>PayloadIdentifier</key><string>%@</string><key>PayloadUUID</key><string>%@</string><key>Name</key><string>%@</string><key>Font</key><data>%@</data></dict>", fontInfo.displayName, UUIDString, fontInfo.displayName, font]];
		
		count++;
	}
	NSString *title = [NSString stringWithFormat:@"%ld font%@", (long)count, (count>1?@"s":@"")];
	
	NSString *profile = [NSString stringWithFormat:@"<?xml version=\"1.0\" encoding=\"UTF-8\"?><!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\"><plist version=\"1.0\"><dict><key>PayloadType</key><string>Configuration</string><key>PayloadVersion</key><integer>1</integer><key>PayloadDisplayName</key><string>xFonts (%@)</string><key>PayloadIdentifier</key><string>xFonts %@</string><key>PayloadUUID</key><string>%@</string><key>PayloadContent</key><array>%@</array></dict></plist>", title, NSUUID.UUID.UUIDString, NSUUID.UUID.UUIDString, fonts];
	
	NSURL *URL = [FontInfo.storageURL URLByAppendingPathComponent:@"xFonts.mobileconfig"];
	// URL = [NSURL fileURLWithPath:@"/"]; // to generate an error
	
	NSError *error;
	if (! [profile writeToURL:URL atomically:YES encoding:NSUTF8StringEncoding error:&error]) {
		ReleaseLog(@"%s error = %@", __PRETTY_FUNCTION__, error);
	}
	else {
		error = nil;
	}
	
	completion(error);
}

/**
 Returns an NSURL [in Documents directory] for the file passed on the parameter.

 @param fileName whose NSURL you need
 @return NSURL to the file
 */
//- (NSURL*)urlForFile:(NSString*)fileName {
//	NSURL *directory = [[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask].firstObject;
//	return [directory URLByAppendingPathComponent:fileName];
//}

/**
 Returns an NSString with the path [in Documents directory] for the file passed on the parameter.

 @param fileName whose path you need
 @return path to the file
 */
//- (NSString*)pathForFile:(NSString*)fileName {
//	NSString *filePath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
//	return [filePath stringByAppendingString:fileName];
//}

/**
 Saves the string "str" to disk on the "fileName" path.

 @param str file to save as a string
 @param fileName path to where the file should be saved
 */
//- (void)saveString:(NSString*)str toFile:(NSString*)fileName {
//	NSString *fileAtPath = [self pathForFile:fileName];
//	if (![[NSFileManager defaultManager] fileExistsAtPath:fileAtPath]) {
//		[[NSFileManager defaultManager] createFileAtPath:fileAtPath contents:nil attributes:nil];
//	}
//	[[str dataUsingEncoding:NSUTF8StringEncoding] writeToFile:fileAtPath atomically:YES];
//}

/**
 Removes the file at the "fileName" path.

 @param fileName path to file you want to delete
 @return true if the file was deleted, false if it couldn't be deleted
 */
//- (BOOL)removeFile:(NSString*)fileName {
//	if (![[fileName substringWithRange:NSMakeRange(0, 1)] isEqualToString:@"/"]) {
//		fileName = [@"/" stringByAppendingString:fileName];
//	}
//	NSString *fileAtPath = [self pathForFile:fileName];
//
//	NSError *error;
//	if (![[NSFileManager defaultManager] removeItemAtPath:fileAtPath error:&error]) {
//		ReleaseLog(@"%s Could not delete file: %@", __PRETTY_FUNCTION__, [error localizedDescription]);
//		return false;
//	}
//	return true;
//}

//#pragma mark - Navigation

//- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
//	if ([segue.identifier isEqualToString:@"HelpSegue"]) {
//		UIViewController *vc = segue.destinationViewController;
////		Set the transitioning delegate to allow for the custom animators
//		vc.transitioningDelegate = self;
//	}
//}

#pragma mark - Notifications

- (void)applicationDidEnterBackground:(UIApplication *)application {
	[self dismissViewControllerAnimated:YES completion:^{
		[self stopHTTPServer];
	}];
}

#pragma mark - UIDocumentPickerDelegate

- (void)documentPicker:(UIDocumentPickerViewController *)controller didPickDocumentsAtURLs:(NSArray <NSURL *>*)URLs
{
	// NOTE: This is called after the selected files are downloaded and the picker view is dismissed.
	
	// TODO: copy the security scoped URLs into the app
	// https://developer.apple.com/library/archive/documentation/FileManagement/Conceptual/DocumentPickerProgrammingGuide/AccessingDocuments/AccessingDocuments.html#//apple_ref/doc/uid/TP40014451-CH2-SW9
	
	DebugLog(@"%s urls = %@", __PRETTY_FUNCTION__, URLs);
	for (NSURL *sourceURL in URLs) {
		BOOL accessingResource = [sourceURL startAccessingSecurityScopedResource];
		NSString *fileName = sourceURL.lastPathComponent;
		NSURL *destinationURL = [FontInfo.storageURL URLByAppendingPathComponent:fileName];
		NSFileManager *fileManager = NSFileManager.defaultManager;
		NSError *error;
		if (! [fileManager fileExistsAtPath:destinationURL.path]) {
			if (! [fileManager copyItemAtURL:sourceURL toURL:destinationURL error:&error]) {
				ReleaseLog(@"%s error = %@", __PRETTY_FUNCTION__, error);
			}
		}
		if (accessingResource) {
			[sourceURL stopAccessingSecurityScopedResource];
		}
	}
	
	[self loadFonts];
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
		[self stopHTTPServer];
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
