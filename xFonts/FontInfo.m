//
//  FontInfo.m
//  xFonts
//
//  Created by Craig Hockenberry on 4/15/20.
//  Copyright © 2020 manolo. All rights reserved.
//

@import CoreText;

#import "FontInfo.h"

#import "DebugLog.h"


@interface FontInfo ()

@property (nonatomic, strong) NSURL *fileURL;
@property (nonatomic, strong) NSString *displayName;
@property (nonatomic, strong) NSString *postScriptName;
@property (nonatomic, strong) NSString *copyrightName;
@property (nonatomic, strong) NSString *descriptionName;
@property (nonatomic, strong) NSString *versionName;
@property (nonatomic, strong) NSString *styleName;
@property (nonatomic, strong) NSString *familyName;
@property (nonatomic, assign) BOOL isMonospaced;

@property (nonatomic, assign) BOOL isInstalled;
@property (nonatomic, assign) NSInteger numberOfGlyphs;

@end

@implementation FontInfo

+ (NSURL *)storageURL
{
	NSArray<NSURL *> *URLs = [NSFileManager.defaultManager URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask];
	NSAssert(URLs != nil && URLs.count > 0, @"Missing document directory");
	return URLs.firstObject;
}

+ (NSURL *)inboxURL
{
	return [self.storageURL URLByAppendingPathComponent:@"Inbox"];
}

- (instancetype)initWithFileURL:(NSURL *)fileURL
{
	if ((self = [self init])) {
		_fileURL = fileURL;
		
		DebugLog(@"%s fileName = %@", __PRETTY_FUNCTION__, self.fileName);

		[self extractPropertiesFromFileURL];
	}
	
	return self;
}

- (NSUInteger)hash
{
	return self.fileURL.hash;
}

#pragma mark Accessors

- (NSString *)fileName
{
	return self.fileURL.lastPathComponent;
}

#pragma mark -

- (void)refresh
{
	[self extractPropertiesFromFileURL];
}

- (BOOL)removeFile
{
	BOOL result = YES;
	
	NSError *error;
	if (! [NSFileManager.defaultManager removeItemAtURL:self.fileURL error:&error]) {
		result = NO;
		ReleaseLog(@"%s Could not delete file: %@", __PRETTY_FUNCTION__, [error localizedDescription]);
	}
	
	return result;
}

#pragma mark - Utility

- (void)extractPropertiesFromFileURL
{
	NSData *fontData = [[NSData alloc] initWithContentsOfURL:self.fileURL];
	if (fontData) {
		CGDataProviderRef providerRef = CGDataProviderCreateWithCFData((CFDataRef)fontData);
		if (providerRef) {
			CGFontRef fontRef = CGFontCreateWithDataProvider(providerRef);
			if (fontRef) {
				self.numberOfGlyphs	= CGFontGetNumberOfGlyphs(fontRef);
				
				self.postScriptName = CFBridgingRelease(CGFontCopyPostScriptName(fontRef));
				self.displayName = CFBridgingRelease(CGFontCopyFullName(fontRef));
				self.isInstalled = NO;

				// https://stackoverflow.com/questions/53359789/get-meta-info-from-uifont-or-cgfont-ios-swift
				CTFontRef textFontRef = CTFontCreateWithGraphicsFont(fontRef, 0, NULL, NULL);
				if (textFontRef) {
					self.copyrightName = CFBridgingRelease(CTFontCopyName(textFontRef, kCTFontCopyrightNameKey));
					self.descriptionName = CFBridgingRelease(CTFontCopyName(textFontRef, kCTFontDescriptionNameKey));
					self.versionName = CFBridgingRelease(CTFontCopyName(textFontRef, kCTFontVersionNameKey));
					self.styleName = CFBridgingRelease(CTFontCopyName(textFontRef, kCTFontStyleNameKey));
					
					self.familyName = CFBridgingRelease(CTFontCopyFamilyName(textFontRef));
					
					CTFontSymbolicTraits symbolicTraits = CTFontGetSymbolicTraits(textFontRef);
					self.isMonospaced = (symbolicTraits & kCTFontTraitMonoSpace) != 0;

					CFStringRef postScriptNameStringRef = CGFontCopyPostScriptName(fontRef);
					CGFontRef existingFontRef = CGFontCreateWithFontName(postScriptNameStringRef);
					if (existingFontRef != NULL) {
						CGFontRelease(existingFontRef);
						self.isInstalled = YES;
					}
					DebugLog(@"%s font %@ installed: %@", __PRETTY_FUNCTION__, self.postScriptName, self.isInstalled ? @"YES" : @"NO");

					CFRelease(textFontRef);
					CFRelease(fontRef);
				}
				else {
					ReleaseLog(@"%s no fontRef", __PRETTY_FUNCTION__);
				}
				
				CFRelease(providerRef);
			}
			else {
				// fallback on file name which _might_ work
				self.postScriptName = [self.fileURL.lastPathComponent stringByDeletingPathExtension];
			}
		}
		else {
			ReleaseLog(@"%s no providerRef", __PRETTY_FUNCTION__);
		}
	}
}

@end
