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
@property (nonatomic, strong) NSString *postscriptName;
@property (nonatomic, strong) NSString *copyrightName;
@property (nonatomic, strong) NSString *descriptionName;

@property (nonatomic, assign) NSInteger numberOfGlyphs;

@end

@implementation FontInfo

+ (NSURL *)storageURL
{
	NSArray<NSURL *> *URLs = [NSFileManager.defaultManager URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask];
	NSAssert(URLs != nil && URLs.count > 0, @"Missing document directory");
	return URLs.firstObject;
}

- (instancetype)initWithFileURL:(NSURL *)fileURL
{
	if ((self = [self init])) {
		_fileURL = fileURL;
		
		[self extractPropertiesFromFileURL];
		[self registerFont];
	}
	
	return self;
}

- (NSUInteger)hash
{
	return self.fileURL.hash;
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

- (void)registerFont
{
	CFErrorRef errorRef;
	if (! CTFontManagerRegisterFontsForURL((CFURLRef)self.fileURL, kCTFontManagerScopeProcess, &errorRef)) {
		if (CFErrorGetCode(errorRef) != kCTFontManagerErrorAlreadyRegistered) {
			CFStringRef errorDescription = CFErrorCopyDescription(errorRef);
			ReleaseLog(@"%s Failed to register font: %@", __PRETTY_FUNCTION__, errorDescription);
			CFRelease(errorDescription);
		}
	}
}

- (void)extractPropertiesFromFileURL
{
	NSData *fontData = [[NSData alloc] initWithContentsOfURL:self.fileURL];
	if (fontData) {
		CGDataProviderRef providerRef = CGDataProviderCreateWithCFData((CFDataRef)fontData);
		if (providerRef) {
			CGFontRef fontRef = CGFontCreateWithDataProvider(providerRef);
			if (fontRef) {
				self.numberOfGlyphs	= CGFontGetNumberOfGlyphs(fontRef);
				
				self.postscriptName = CFBridgingRelease(CGFontCopyPostScriptName(fontRef));
				self.displayName = CFBridgingRelease(CGFontCopyFullName(fontRef));

				// https://stackoverflow.com/questions/53359789/get-meta-info-from-uifont-or-cgfont-ios-swift
				CTFontRef textFontRef = CTFontCreateWithGraphicsFont(fontRef, 0, NULL, NULL);
				if (textFontRef) {
					self.copyrightName = CFBridgingRelease(CTFontCopyName(textFontRef, kCTFontCopyrightNameKey));
					self.descriptionName = CFBridgingRelease(CTFontCopyName(textFontRef, kCTFontDescriptionNameKey));

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
				self.postscriptName = [self.fileURL.lastPathComponent stringByDeletingPathExtension];
			}
		}
		else {
			ReleaseLog(@"%s no providerRef", __PRETTY_FUNCTION__);
		}
	}
}

@end
