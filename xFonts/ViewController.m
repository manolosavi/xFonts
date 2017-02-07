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
}

@end

@implementation ViewController

- (void)viewDidLoad {
	[super viewDidLoad];
	_selectedFonts = [NSMutableArray array];
	
	[self startHTTPServer];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loadFonts) name:@"reloadFonts" object:nil];
	
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
	}
	_allFonts = tempFonts;
	_selectedFonts = [_allFonts mutableCopy];
	
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
	
	return cell;
}

- (void)startHTTPServer {
	http = [[RoutingHTTPServer alloc] init];
	[http setPort:3333];
	[http setDefaultHeader:@"Content-Type" value:@"application/x-apple-aspen-config"];
	[http setDocumentRoot:[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, true) objectAtIndex:0]];
	
	[http handleMethod:@"GET" withPath:@"/" block:^(RouteRequest *request, RouteResponse *response) {
		[response setHeader:@"Content-Type" value:@"text/html"];
		
		[response respondWithString:@"<!doctype html><html><head><meta charset=\"utf-8\" /><meta name=\"viewport\" content=\"width=device-width, initial-scale=1\"><link rel=\"stylesheet\" type=\"text/css\" href=\"css/main.css\"><title>xFonts - Install Profile</title></head><body><header><h1>xFonts - Install Profile</h1></header><p>To install the fonts tap <a href=\"/xFonts.mobileconfig\">here</a>.</p></body></html>"];
	}];
	
	[http start:nil];
}

- (IBAction)openInstallProfilePage:(id)sender {
	
	[self saveFontsProfile:^{
		NSURL *URL = [NSURL URLWithString:[NSString stringWithFormat:@"http://localhost:3333/"]];
		[[UIApplication sharedApplication] openURL:URL options:@{} completionHandler:^(BOOL success) {
			
		}];
	}];
}

- (void)saveFontsProfile:(void(^)())completion {
	NSString *fonts = @"";
	
	for (NSDictionary *dict in _selectedFonts) {
		NSURL *url = [self urlForFile:dict[@"file"]];
		
		NSString *name = [dict[@"name"] stringByReplacingOccurrencesOfString:@".otf" withString:@""];
		name = [name stringByReplacingOccurrencesOfString:@".ttf" withString:@""];
		
		NSString *font = [[[NSData alloc] initWithContentsOfURL:url] base64EncodedStringWithOptions:NSDataBase64EncodingEndLineWithLineFeed];
			
		fonts = [fonts stringByAppendingString:[NSString stringWithFormat:@"<dict><key>PayloadType</key><string>com.apple.font</string><key>PayloadVersion</key><integer>1</integer><key>PayloadIdentifier</key><string>%@</string><key>PayloadUUID</key><string>%@</string><key>Name</key><string>%@</string><key>Font</key><data>%@</data></dict>", name, name, name, font]];
	}
	NSString *profile = [NSString stringWithFormat:@"<?xml version=\"1.0\" encoding=\"UTF-8\"?><!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\"><plist version=\"1.0\"><dict><key>PayloadType</key><string>Configuration</string><key>PayloadVersion</key><integer>1</integer><key>PayloadDisplayName</key><string>xFonts</string><key>PayloadIdentifier</key><string>xFonts</string><key>PayloadUUID</key><string>xFonts</string><key>PayloadContent</key><array>%@</array></dict></plist>", fonts];
	
	[self write:profile toFile:@"/xFonts.mobileconfig"];
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

- (void)write:(NSString*)str toFile:(NSString*)fileName {
	NSString *fileAtPath = [self pathForFile:fileName];
	if (![[NSFileManager defaultManager] fileExistsAtPath:fileAtPath]) {
		[[NSFileManager defaultManager] createFileAtPath:fileAtPath contents:nil attributes:nil];
	}
	[[str dataUsingEncoding:NSUTF8StringEncoding] writeToFile:fileAtPath atomically:true];
}

@end
