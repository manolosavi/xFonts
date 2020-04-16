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

- (instancetype)initWithFileURL:(NSURL *)fileURL displayName:(NSString *)displayName postscriptName:(NSString *)postscriptName;

@property (nonatomic, readonly) NSURL *fileURL;
@property (nonatomic, readonly) NSString *displayName;
@property (nonatomic, readonly) NSString *postscriptName;

- (BOOL)removeFile; // returns YES if successful

@end

NS_ASSUME_NONNULL_END
