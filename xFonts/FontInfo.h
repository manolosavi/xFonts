//
//  FontInfo.h
//  xFonts
//
//  Created by Craig Hockenberry on 4/15/20.
//  Copyright © 2020 manolo. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface FontInfo : NSObject

@property (class, nonatomic, readonly) NSURL *storageURL;
@property (class, nonatomic, readonly) NSURL *inboxURL;

- (instancetype)initWithFileURL:(NSURL *)fileURL;

@property (readonly) NSUInteger hash;

@property (nonatomic, readonly) NSURL *fileURL;
@property (nonatomic, readonly) NSString *fileName;
@property (nonatomic, readonly) NSString *postScriptName;
@property (nonatomic, readonly, nullable) NSString *displayName;
@property (nonatomic, readonly, nullable) NSString *copyrightName;
@property (nonatomic, readonly, nullable) NSString *descriptionName;
@property (nonatomic, readonly, nullable) NSString *versionName;
@property (nonatomic, readonly, nullable) NSString *styleName;
@property (nonatomic, readonly, nullable) NSString *familyName;

@property (nonatomic, readonly) BOOL isRegistered;
@property (nonatomic, readonly) NSInteger numberOfGlyphs;

- (void)refresh; // reload cached properties (everything derived from fileURL)

- (BOOL)removeFile; // returns YES if successful

@end

NS_ASSUME_NONNULL_END
