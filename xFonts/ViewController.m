//
//  ViewController.m
//  xFonts
//
//  Created by manolo on 2/1/17.
//  Copyright © 2017 manolo. All rights reserved.
//

#import <SafariServices/SafariServices.h>

#import "ViewController.h"

#import "DetailViewController.h"
#import "TabBarController.h"
#import "HeaderView.h"
#import "RoutingHTTPServer.h"

#import "DebugLog.h"

@interface ViewController () <SFSafariViewControllerDelegate, UIDocumentPickerDelegate>

@property (nonatomic, strong) RoutingHTTPServer *http;

@property (nonatomic, weak) IBOutlet UIBarButtonItem *installButton;
@property (nonatomic, weak) IBOutlet UIBarButtonItem *addButton;

@property (nonatomic, strong) NSArray<FontInfo *> *fonts;

@end

@implementation ViewController

- (void)viewDidLoad
{
	[super viewDidLoad];

	NSNotificationCenter *notificationCenter = NSNotificationCenter.defaultCenter;
	[notificationCenter addObserver:self selector:@selector(applicationDidEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
	[notificationCenter addObserver:self selector:@selector(applicationDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];

	// TODO: Add importFonts to copy files from Documents/Inbox to top-level folder if they don't already exist?

	[self loadFonts];
	[self updateNavigation];
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	
	//if (self.fonts.count == 0) {
		[self showHelpOverlay];
	//}
}

- (void)didReceiveMemoryWarning
{
	[super didReceiveMemoryWarning];
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
	if ([segue.destinationViewController isKindOfClass:[DetailViewController class]]) {
		DetailViewController *viewController = (DetailViewController *)segue.destinationViewController;
		NSIndexPath *selectedIndexPath = self.tableView.indexPathForSelectedRow;
		if (selectedIndexPath) {
			NSInteger selectedIndex = selectedIndexPath.item;
			if (selectedIndex >= 0 && selectedIndex < self.fonts.count) {
				FontInfo *fontInfo = self.fonts[selectedIndex];
				viewController.fontInfo = fontInfo;
			}
		}
	}
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}

#pragma mark - Actions

- (IBAction)installProfile:(id)sender
{
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
		}
	}];
}

- (IBAction)addFonts:(id)sender
{
	NSArray<NSString *> *allowedUTIs = @[ @"public.truetype-font" , @"public.opentype-font"];
	UIDocumentPickerViewController *viewController = [[UIDocumentPickerViewController alloc] initWithDocumentTypes:allowedUTIs inMode:UIDocumentPickerModeImport];
	viewController.view.tintColor = self.view.tintColor;
	viewController.allowsMultipleSelection = YES;
	viewController.delegate = self;
	
	[self presentViewController:viewController animated:YES completion:^{
		// TODO: something here?
	}];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return self.fonts.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
	
	cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	
	FontInfo *fontInfo = self.fonts[indexPath.row];
	
	UIFont *bodyFont = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];

	cell.textLabel.text = fontInfo.displayName;
	cell.textLabel.font = [UIFont fontWithName:fontInfo.postScriptName size:bodyFont.pointSize];
	cell.textLabel.adjustsFontSizeToFitWidth = YES;
	cell.textLabel.minimumScaleFactor = 0.5;

	if (fontInfo.isRegistered) {
		cell.imageView.image = [UIImage systemImageNamed:@"checkmark.circle"];
	}
	else {
		cell.imageView.image = [UIImage systemImageNamed:@"arrow.down.circle.fill"];
//		cell.imageView.image = [UIImage systemImageNamed:@"arrow.uturn.up.circle"];
	}
	
	UIView *selection = [UIView new];
	selection.backgroundColor = [UIColor colorNamed:@"appSelection"];
	cell.selectedBackgroundView = selection;
	
	return cell;
}

#pragma mark - UITableViewDelegate

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
	return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
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

				[self updateNavigation];

				[tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
			}
		}];
		
		[alertController addAction:cancelAction];
		[alertController addAction:deleteAction];
		
		[self presentViewController:alertController animated:YES completion:nil];
	}
}

#pragma mark - Utility

- (void)loadFonts
{
	NSError *error = nil;
	NSArray<NSURL *> *URLs = [NSFileManager.defaultManager contentsOfDirectoryAtURL:FontInfo.storageURL includingPropertiesForKeys:nil options:(NSDirectoryEnumerationSkipsSubdirectoryDescendants) error:&error];
	if (! URLs) {
		ReleaseLog(@"%s error = %@", __PRETTY_FUNCTION__, error);
	}
	else {
		// NOTE: This causes all current FontInfo instances to be deallocated and become unregistered. The
		// new instances created below will re-register the fonts during initialization.
		self.fonts = nil;
		
		NSMutableArray *loadedFonts = [NSMutableArray array];

		for (NSURL *URL in URLs) {
			NSString *fileName = URL.lastPathComponent;
			NSString *fileExtension = fileName.pathExtension;
			
			BOOL validFont = NO;
			if ([fileExtension.lowercaseString isEqual:@"otf"]) {
				validFont = YES;
			}
			else if ([fileExtension.lowercaseString isEqual:@"ttf"]) {
				validFont = YES;
			}
			
			if (validFont) {
				FontInfo *fontInfo = [[FontInfo alloc] initWithFileURL:URL];
				[loadedFonts addObject:fontInfo];
			}
		}
		
		[loadedFonts sortUsingComparator:^NSComparisonResult(FontInfo *firstFontInfo, FontInfo *secondFontInfo) {
			return [firstFontInfo.displayName compare:secondFontInfo.displayName];
		}];
		
		self.fonts = [loadedFonts copy];
		
		[self.tableView reloadData];
	}
}

- (void)updateNavigation
{
	NSInteger addedCount = self.fonts.count;
	NSInteger installCount = 0;
	for (FontInfo *fontInfo in self.fonts) {
		if (! fontInfo.isRegistered) {
			installCount += 1;
		}
	}

	NSAssert([self.tableView.tableHeaderView isKindOfClass:[HeaderView class]], @"HeaderView not configured");
	HeaderView *headerView = (HeaderView *)self.tableView.tableHeaderView;
	[headerView setFontAddedCount:addedCount installCount:installCount];
	
	// NOTE: It would be nice to enable or disable the install button, but we can't really know what happens after a font is deleted.
	// We could track the start of the install, but there's no indication that the process completed successfully. Moving the font to
	// a temporary holding area and checking if it's registered at next launch might work, but this adds a lot of complexity and
	// given the disjointed nature of the install process, I'd say that's unlikely.
	//
	//self.installButton.enabled = (installCount > 0);
}

#pragma mark -

/**
 Starts the HTTP Server and sets the response to the root directory to allow the install of profiles.
 */
- (void)startHTTPServer
{
	self.http = [RoutingHTTPServer new];
	[self.http setPort:3333];
	[self.http setDefaultHeader:@"Content-Type" value:@"application/x-apple-aspen-config"];
	[self.http setDocumentRoot:[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0]];
	
	[self.http handleMethod:@"GET" withPath:@"/" block:^(RouteRequest *request, RouteResponse *response) {
		// This is what the server will respond with when going to the root directory.
		[response setHeader:@"Content-Type" value:@"text/html"];
		
		// Get the html file from the main bundle, send it as the response string.
		NSString *path = [NSBundle.mainBundle pathForResource:@"index" ofType:@"html"];
		NSString *html = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
		NSString *productName = [NSBundle.mainBundle objectForInfoDictionaryKey:@"CFBundleDisplayName"];

		html = [html stringByReplacingOccurrencesOfString:@"$(PRODUCT_NAME)" withString:productName];
		
		[response respondWithString:html];
	}];
	
	[self.http start:nil];
}

- (void)stopHTTPServer
{
	[self.http stop];
}

#pragma mark -

/*
static NSString *const profilePayloadTemplate =
	@"<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
	"<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">\n"
	"<plist version=\"1.0\">\n"
	"<dict>\n"
	"	<key>PayloadType</key>\n"
	"	<string>Configuration</string>\n"
	"	<key>PayloadVersion</key>\n"
	"	<integer>1</integer>\n"
	"	<key>PayloadDisplayName</key>\n"
	"	<string>xFonts Installation</string>\n"
	"	<key>PayloadIdentifier</key>\n"
	"	<string>com.iconfactory.xfonts</string>\n"
	"	<key>PayloadUUID</key>\n"
	"	<string>%@</string>\n"
	"	<key>PayloadContent</key>\n"
	"	<array>\n"
	"%@\n"
	"	</array>\n"
	"</dict>\n"
	"</plist>";

static NSString *const fontPayloadTemplate =
	@"		<dict>\n"
	"			<key>PayloadType</key>\n"
	"			<string>com.apple.font</string>\n"
	"			<key>PayloadVersion</key>\n"
	"			<integer>1</integer>\n"
	"			<key>PayloadIdentifier</key>\n"
	"			<string>com.iconfactory.xfonts.%@</string>\n"
	"			<key>PayloadUUID</key>\n"
	"			<string>%@</string>\n"
	"			<key>Name</key>\n"
	"			<string>%@</string>\n"
	"			<key>Font</key>\n"
	"			<data>%@</data>\n"
	"		</dict>\n";
*/

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
		"<string>%@ Installation</string>"
		"<key>PayloadDescription</key>"
		"<string>This profile installs the fonts managed by %@.</string>"
		"<key>PayloadIdentifier</key>"
		"<string>com.iconfactory.xfonts</string>"
		"<key>PayloadUUID</key>"
		"<string>%@</string>"
		"<key>PayloadContent</key>"
		"<array>"
			"%@"
		"</array>"
	"</dict>"
	"</plist>";

static NSString *const fontPayloadTemplate =
	@"<dict>"
		"<key>PayloadType</key>"
		"<string>com.apple.font</string>"
		"<key>PayloadVersion</key>"
		"<integer>1</integer>"
		"<key>PayloadIdentifier</key>"
		"<string>com.iconfactory.xfonts.%@</string>"
		"<key>PayloadUUID</key>"
		"<string>%@</string>"
		"<key>Name</key>"
		"<string>%@</string>"
		"<key>Font</key>"
		"<data>%@</data>"
	"</dict>";

/**
 Goes through the list of fonts and adds all the selected ones to the profile, then saves the completed profile to the Documents directory.

 @param completion this block is called when the profile has completed saving to disk
 */
- (void)saveFontsProfile:(void(^)(NSError *error))completion
{
	NSString *productName = [NSBundle.mainBundle objectForInfoDictionaryKey:@"CFBundleDisplayName"];

	NSString *fontsPayload = @"";
	for (FontInfo *fontInfo in self.fonts) {
		NSString *fontEncoded = [[[NSData alloc] initWithContentsOfURL:fontInfo.fileURL] base64EncodedStringWithOptions:NSDataBase64EncodingEndLineWithLineFeed];
		
		NSString *fontPayload = [NSString stringWithFormat:fontPayloadTemplate, fontInfo.postScriptName, NSUUID.UUID.UUIDString, fontInfo.displayName, fontEncoded];
		
		fontsPayload = [fontsPayload stringByAppendingString:fontPayload];
	}
	
	NSString *profile = [NSString stringWithFormat:profilePayloadTemplate, productName, productName, NSUUID.UUID.UUIDString, fontsPayload];

	NSURL *URL = [FontInfo.storageURL URLByAppendingPathComponent:@"xFonts.mobileconfig"];
	// URL = [NSURL fileURLWithPath:@"/"]; // to generate an error during write
	
	NSError *error;
	if (! [profile writeToURL:URL atomically:YES encoding:NSUTF8StringEncoding error:&error]) {
		ReleaseLog(@"%s error = %@", __PRETTY_FUNCTION__, error);
	}
	else {
		error = nil;
	}
	
	completion(error);
}

#pragma mark -

- (void)showHelpOverlay
{
	NSAssert([self.tabBarController isKindOfClass:[TabBarController class]], @"TabBarController not configured");
	TabBarController *tabBarController = (TabBarController *)self.tabBarController;
	[tabBarController showHelpOverlay];
}

#pragma mark - Notifications

- (void)applicationDidEnterBackground:(UIApplication *)application
{
	DebugLog(@"%s shutting down server...", __PRETTY_FUNCTION__);
	[self dismissViewControllerAnimated:YES completion:^{
		[self stopHTTPServer];
	}];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
	DebugLog(@"%s refreshing font info...", __PRETTY_FUNCTION__);
	for (FontInfo *fontInfo in self.fonts) {
		[fontInfo refresh];
	}
}

#pragma mark - UIDocumentPickerDelegate

- (void)documentPicker:(UIDocumentPickerViewController *)controller didPickDocumentsAtURLs:(NSArray <NSURL *>*)URLs
{
	DebugLog(@"%s urls = %@", __PRETTY_FUNCTION__, URLs);
	// NOTE: This is called after the selected files are downloaded and the picker view is dismissed.
	
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
	[self updateNavigation];
}

- (void)documentPickerWasCancelled:(UIDocumentPickerViewController *)controller
{
	DebugLog(@"%s called", __PRETTY_FUNCTION__);
	// NOTE: Called if the user dismisses the document picker without selecting a document (using the Cancel button).
}

#pragma mark - SFSafariViewControllerDelegate

- (void)safariViewControllerDidFinish:(SFSafariViewController *)controller
{
	[self dismissViewControllerAnimated:YES completion:^{
		[self stopHTTPServer];
	}];
}

@end
