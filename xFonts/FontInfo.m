//
//  FontInfo.m
//  xFonts
//
//  Created by Craig Hockenberry on 4/15/20.
//  Copyright © 2020 manolo. All rights reserved.
//

#import "FontInfo.h"

#import "DebugLog.h"


@interface FontInfo ()

@property (nonatomic, strong) NSURL *fileURL;
@property (nonatomic, strong) NSString *displayName;
@property (nonatomic, strong) NSString *postscriptName;

@end

@implementation FontInfo

+ (NSURL *)storageURL
{
	NSArray<NSURL *> *URLs = [NSFileManager.defaultManager URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask];
	NSAssert(URLs != nil && URLs.count > 0, @"Missing document directory");
	return URLs.firstObject;
}

- (instancetype)initWithFileURL:(NSURL *)fileURL displayName:(NSString *)displayName postscriptName:(NSString *)postscriptName
{
	if ((self = [self init])) {
		_fileURL = fileURL;
		_displayName = displayName;
		_postscriptName = postscriptName;
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

@end
