//
//  FYFontCache.h
//  Fonty
//
//  Created by 颜为晨 on 16/7/2.
//  Copyright © 2016年 颜为晨. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FYFontModel.h"

@interface FYFontCache : NSObject

@property (nonatomic, copy, readonly) NSString *diskCacheDirectoryPath;

+ (instancetype)sharedFontCache;

- (BOOL)cacheObject:(id)object cacheFileName:(NSString *)cacheFileName;
- (instancetype)objectFromCacheWithFileName:(NSString *)cacheFileName;

- (NSString *)cachedFilePathWithDownloadURL:(NSURL *)downloadURL;
- (void)cacheFileAtLocolURL:(NSURL *)locolURL fromDownloadURL:(NSURL *)downloadURL;
- (void)cleanCachedFileWithDownloadURL:(NSURL *)downloadURL;


@property (nonatomic, copy) void(^didCleanFileBlock)(NSString *downloadURLString);
@property (nonatomic, copy) void(^didCacheFileBlock)(NSString *downloadURLString);

@end
