//
//  ViewController.m
//  xFonts
//
//  Created by manolo on 2/1/17.
//  Copyright © 2017 manolo. All rights reserved.
//

#import "ViewController.h"
#import "RoutingHTTPServer.h"

@interface ViewController () {
	RoutingHTTPServer *http;
	BOOL fullSelection;
}

@end

@implementation ViewController

- (void)viewDidLoad {
	[super viewDidLoad];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loadFonts) name:@"reloadFonts" object:nil];
	
	_selectedFonts = [NSMutableArray array];
	fullSelection = true;
	
	[_selectButton setPossibleTitles:[NSSet setWithObjects: @"None", @"All", nil]];
	
	[self startHTTPServer];
	[self loadFonts];
}

- (void)loadFonts {
	NSString *file;
	NSMutableArray *tempFonts = [NSMutableArray array];
	NSDirectoryEnumerator *dirEnum = [[NSFileManager defaultManager] enumeratorAtPath:[NSHomeDirectory() stringByAppendingPathComponent:@"Documents"]];
	while ((file = [dirEnum nextObject])) {
		if ([[file pathExtension] isEqualToString:@"otf"] || [[file pathExtension] isEqualToString:@"ttf"]) {
			NSString *fontName = [[file lastPathComponent] stringByReplacingOccurrencesOfString:@".otf" withString:@""];
			[fontName stringByReplacingOccurrencesOfString:@".ttf" withString:@""];
			
			NSData *fontData = [[NSData alloc] initWithContentsOfURL:[self urlForFile:file]];
			CFErrorRef error;
			CGDataProviderRef provider = CGDataProviderCreateWithCFData((CFDataRef)fontData);
			CGFontRef font = CGFontCreateWithDataProvider(provider);
			if (!CTFontManagerRegisterGraphicsFont(font, &error)) {
				CFStringRef errorDescription = CFErrorCopyDescription(error);
				if (CFErrorGetCode(error) != 105) {
					NSLog(@"Failed to load font: %@", errorDescription);
				}
				CFRelease(errorDescription);
			} else {
				fontName = (NSString *)CFBridgingRelease(CGFontCopyPostScriptName(font));
			}
			CFRelease(font);
			CFRelease(provider);
			
			[tempFonts addObject:[@{@"file":file, @"name":fontName} mutableCopy]];
		}
		[_selectedFonts addObject:@1];
	}
	_allFonts = tempFonts;
	
	[_tableView reloadData];
}

- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];
}

#pragma mark - UITableView Delegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	tableView.hidden = _allFonts.count == 0;
	return _allFonts.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
	NSString *fontURL = _allFonts[indexPath.row][@"file"];
	
	cell.textLabel.text = [fontURL lastPathComponent];
	
	NSString *fontName = _allFonts[indexPath.row][@"name"];
	cell.textLabel.font = [UIFont fontWithName:fontName size:16];
	
	cell.textLabel.layer.opacity = [_selectedFonts[indexPath.row] isEqual:@1] ? 1 : 0.1;
	
	UIView *selection = [[UIView alloc] init];
	selection.backgroundColor = [UIColor colorWithHue:260/360.0 saturation:0.5 brightness:0.8 alpha:1];
	cell.selectedBackgroundView = selection;
	
	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	_selectedFonts[indexPath.row] = [_selectedFonts[indexPath.row] isEqual:@1] ? @0 : @1;
	
	fullSelection = ![_selectedFonts containsObject:@0];
	if (fullSelection) {
		_selectButton.title = @"None";
	} else {
		_selectButton.title = @"All";
	}
	
	_installButton.enabled = [_selectedFonts containsObject:@1];
	
	[tableView reloadData];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
	return true;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
	if (editingStyle == UITableViewCellEditingStyleDelete) {
		UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:@"Delete Font" message:@"Are you sure you want to delete this font? This cannot be undone." preferredStyle:UIAlertControllerStyleAlert];
		
		UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
		UIAlertAction *deleteAction = [UIAlertAction actionWithTitle:@"Delete" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
			NSDictionary *dict = _allFonts[indexPath.row];
			if ([self removeFile:dict[@"file"]]) {
				[_selectedFonts removeObject:dict];
				
				NSMutableArray *array = [_allFonts mutableCopy];
				[array removeObjectAtIndex:indexPath.row];
				_allFonts = array;
				
				[tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
			}
		}];
		
		[alertVC addAction:cancelAction];
		[alertVC addAction:deleteAction];
		
		[self presentViewController:alertVC animated:true completion:nil];
	}
}

- (IBAction)invertSelection:(id)sender {
	for (int i=0; i<_selectedFonts.count; i++) {
		_selectedFonts[i] = fullSelection ? @0 : @1;
	}
	
	fullSelection = !fullSelection;
	if (fullSelection) {
		_selectButton.title = @"None";
	} else {
		_selectButton.title = @"All";
	}
	_installButton.enabled = fullSelection;
	[_tableView reloadData];
}

- (void)startHTTPServer {
	http = [[RoutingHTTPServer alloc] init];
	[http setPort:3333];
	[http setDefaultHeader:@"Content-Type" value:@"application/x-apple-aspen-config"];
	[http setDocumentRoot:[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, true) objectAtIndex:0]];
	
	[http handleMethod:@"GET" withPath:@"/" block:^(RouteRequest *request, RouteResponse *response) {
		[response setHeader:@"Content-Type" value:@"text/html"];
		
		NSString *path = [[NSBundle mainBundle] pathForResource:@"index" ofType:@"html"];
		NSString *html = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
		
		[response respondWithString:html];
	}];
	
	[http start:nil];
}

- (IBAction)openInstallProfilePage:(id)sender {
	[self saveFontsProfile:^{
		NSURL *URL = [NSURL URLWithString:[NSString stringWithFormat:@"http://localhost:3333/"]];
		[[UIApplication sharedApplication] openURL:URL options:@{} completionHandler:nil];
	}];
}

- (void)saveFontsProfile:(void(^)())completion {
	NSString *fonts = @"";
	for (int i=0; i<_allFonts.count; i++) {
		if ([_selectedFonts[i] isEqual:@0]) {
			continue;
		}
		NSDictionary *dict = _allFonts[i];
		NSURL *url = [self urlForFile:dict[@"file"]];
		
		NSString *name = [dict[@"name"] stringByReplacingOccurrencesOfString:@".otf" withString:@""];
		name = [name stringByReplacingOccurrencesOfString:@".ttf" withString:@""];
		
		NSString *font = [[[NSData alloc] initWithContentsOfURL:url] base64EncodedStringWithOptions:NSDataBase64EncodingEndLineWithLineFeed];
			
		fonts = [fonts stringByAppendingString:[NSString stringWithFormat:@"<dict><key>PayloadType</key><string>com.apple.font</string><key>PayloadVersion</key><integer>1</integer><key>PayloadIdentifier</key><string>%@</string><key>PayloadUUID</key><string>%@</string><key>Name</key><string>%@</string><key>Font</key><data>%@</data></dict>", name, [[NSUUID UUID] UUIDString], name, font]];
	}
	
	NSString *profile = [NSString stringWithFormat:@"<?xml version=\"1.0\" encoding=\"UTF-8\"?><!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\"><plist version=\"1.0\"><dict><key>PayloadType</key><string>Configuration</string><key>PayloadVersion</key><integer>1</integer><key>PayloadDisplayName</key><string>xFonts</string><key>PayloadIdentifier</key><string>xFonts</string><key>PayloadUUID</key><string>%@</string><key>PayloadContent</key><array>%@</array></dict></plist>", [[NSUUID UUID] UUIDString], fonts];
	
	[self saveString:profile toFile:@"/xFonts.mobileconfig"];
	completion();
}

- (NSURL*)urlForFile:(NSString*)fileName {
	NSURL *directory = [[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask].firstObject;
	return [directory URLByAppendingPathComponent:fileName];
}

- (NSString*)pathForFile:(NSString*)fileName {
	NSString *filePath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, true).firstObject;
	return [filePath stringByAppendingString:fileName];
}

- (void)saveString:(NSString*)str toFile:(NSString*)fileName {
	NSString *fileAtPath = [self pathForFile:fileName];
	if (![[NSFileManager defaultManager] fileExistsAtPath:fileAtPath]) {
		[[NSFileManager defaultManager] createFileAtPath:fileAtPath contents:nil attributes:nil];
	}
	[[str dataUsingEncoding:NSUTF8StringEncoding] writeToFile:fileAtPath atomically:true];
}

- (BOOL)removeFile:(NSString*)fileName {
	if (![[fileName substringWithRange:NSMakeRange(0, 1)] isEqualToString:@"/"]) {
		fileName = [@"/" stringByAppendingString:fileName];
	}
	NSString *fileAtPath = [self pathForFile:fileName];
	
	NSError *error;
	if (![[NSFileManager defaultManager] removeItemAtPath:fileAtPath error:&error]) {
		NSLog(@"Could not delete file: %@", [error localizedDescription]);
		return false;
	}
	return true;
}

@end
