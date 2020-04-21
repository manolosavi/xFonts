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
		
		DebugLog(@"%s fileName = %@", __PRETTY_FUNCTION__, self.fileName);

		[self extractPropertiesFromFileURL];
		[self registerFont];
	}
	
	return self;
}

- (void)dealloc
{
	DebugLog(@"%s fileName = %@", __PRETTY_FUNCTION__, self.fileName);
	
	[self unregisterFont];
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

- (BOOL)isRegistered
{
	BOOL result = NO;
	
	[self unregisterFont];
	CGFontRef fontRef = CGFontCreateWithFontName((CFStringRef)self.postScriptName);
	if (fontRef) {
		result = YES;
		CFRelease(fontRef);
	}
	[self registerFont];
	
	return result;
}

#pragma mark -

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
		if (CFErrorGetCode(errorRef) != kCTFontManagerErrorAlreadyRegistered) { // error 105
			CFStringRef errorDescription = CFErrorCopyDescription(errorRef);
			ReleaseLog(@"%s Failed to register font %@ = %@", __PRETTY_FUNCTION__, self.postScriptName, errorDescription);
			CFRelease(errorDescription);
		}
	}
}

- (void)unregisterFont
{
	CFErrorRef errorRef;
	if (! CTFontManagerUnregisterFontsForURL((CFURLRef)self.fileURL, kCTFontManagerScopeProcess, &errorRef)) {
		if (CFErrorGetCode(errorRef) != kCTFontManagerErrorNotRegistered) { // error 201
			CFStringRef errorDescription = CFErrorCopyDescription(errorRef);
			ReleaseLog(@"%s Failed to unregister font %@ = %@", __PRETTY_FUNCTION__, self.postScriptName, errorDescription);
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
				
				self.postScriptName = CFBridgingRelease(CGFontCopyPostScriptName(fontRef));
				self.displayName = CFBridgingRelease(CGFontCopyFullName(fontRef));

				// https://stackoverflow.com/questions/53359789/get-meta-info-from-uifont-or-cgfont-ios-swift
				CTFontRef textFontRef = CTFontCreateWithGraphicsFont(fontRef, 0, NULL, NULL);
				if (textFontRef) {
					self.copyrightName = CFBridgingRelease(CTFontCopyName(textFontRef, kCTFontCopyrightNameKey));
					self.descriptionName = CFBridgingRelease(CTFontCopyName(textFontRef, kCTFontDescriptionNameKey));
					self.versionName = CFBridgingRelease(CTFontCopyName(textFontRef, kCTFontVersionNameKey));
					self.styleName = CFBridgingRelease(CTFontCopyName(textFontRef, kCTFontStyleNameKey));
					
					self.familyName = CFBridgingRelease(CTFontCopyFamilyName(textFontRef));
					
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
