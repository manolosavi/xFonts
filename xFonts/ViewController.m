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

	[NSNotificationCenter.defaultCenter addObserver:self selector:@selector(applicationDidEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];

	// TODO: Add importFonts to copy files from Documents/Inbox to top-level folder if they don't already exist?

	[self loadFonts];
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	
	[self showHelpOverlay];
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
	
#if 0
	cell.textLabel.text = fontInfo.displayName;
#else
	cell.textLabel.text = [NSString stringWithFormat:@"%@ %s", fontInfo.displayName, (fontInfo.isRegistered ? "" : "*")];
#endif
	
	cell.textLabel.font = [UIFont fontWithName:fontInfo.postScriptName size:18.0];
	cell.textLabel.adjustsFontSizeToFitWidth = YES;
	cell.textLabel.minimumScaleFactor = 0.5;

	UIView *selection = [UIView new];
	selection.backgroundColor = [UIColor colorNamed:@"appSelection"];
	cell.selectedBackgroundView = selection;
	
	return cell;
}

#pragma mark - UITableViewDelegate

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
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
	NSMutableArray *loadedFonts = [NSMutableArray array];

	NSError *error = nil;
	NSArray<NSURL *> *URLs = [NSFileManager.defaultManager contentsOfDirectoryAtURL:FontInfo.storageURL includingPropertiesForKeys:nil options:(NSDirectoryEnumerationSkipsSubdirectoryDescendants) error:&error];
	if (! URLs) {
		ReleaseLog(@"%s error = %@", __PRETTY_FUNCTION__, error);
	}
	else {
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
		
		[loadedFonts sortUsingComparator:^NSComparisonResult(FontInfo *fontInfo1, FontInfo *fontInfo2) {
			return [fontInfo1.displayName compare:fontInfo2.displayName];
		}];
		
		self.fonts = [loadedFonts copy];
		
		[self.tableView reloadData];
	}
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
		NSString *path = [[NSBundle mainBundle] pathForResource:@"index" ofType:@"html"];
		NSString *html = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
		
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
		"<string>xFonts Installation</string>"
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
	//NSInteger count = 0;
	NSString *fontsPayload = @"";
	for (int i=0; i<self.fonts.count; i++) {
		FontInfo *fontInfo = self.fonts[i];

		//NSURL *url = [self urlForFile:fontInfo.filePath];
		
		NSString *fontEncoded = [[[NSData alloc] initWithContentsOfURL:fontInfo.fileURL] base64EncodedStringWithOptions:NSDataBase64EncodingEndLineWithLineFeed];
		
		NSString *fontPayload = [NSString stringWithFormat:fontPayloadTemplate, fontInfo.postScriptName, NSUUID.UUID.UUIDString, fontInfo.displayName, fontEncoded];
		
		fontsPayload = [fontsPayload stringByAppendingString:fontPayload];
//		fonts = [fonts stringByAppendingString:[NSString stringWithFormat:@"<dict><key>PayloadType</key><string>com.apple.font</string><key>PayloadVersion</key><integer>1</integer><key>PayloadIdentifier</key><string>%@</string><key>PayloadUUID</key><string>%@</string><key>Name</key><string>%@</string><key>Font</key><data>%@</data></dict>", fontInfo.displayName, UUIDString, fontInfo.displayName, font]];
		
		//count++;
	}
	//NSString *title = [NSString stringWithFormat:@"%ld font%@", (long)count, (count>1?@"s":@"")];
	
	//NSString *profile = [NSString stringWithFormat:@"<?xml version=\"1.0\" encoding=\"UTF-8\"?><!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\"><plist version=\"1.0\"><dict><key>PayloadType</key><string>Configuration</string><key>PayloadVersion</key><integer>1</integer><key>PayloadDisplayName</key><string>xFonts (%@)</string><key>PayloadIdentifier</key><string>xFonts %@</string><key>PayloadUUID</key><string>%@</string><key>PayloadContent</key><array>%@</array></dict></plist>", title, NSUUID.UUID.UUIDString, NSUUID.UUID.UUIDString, fonts];
	
	NSString *profile = [NSString stringWithFormat:profilePayloadTemplate, NSUUID.UUID.UUIDString, fontsPayload];

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
	[self dismissViewControllerAnimated:YES completion:^{
		[self stopHTTPServer];
	}];
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
