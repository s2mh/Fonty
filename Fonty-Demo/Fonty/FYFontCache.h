//
//  FYFontCache.h
//  Fonty
//
//  Created by 颜为晨 on 16/7/2.
//  Copyright © 2016年 颜为晨. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface FYFontCache : NSObject

@property (nonatomic, copy, readonly) NSString *diskCacheDirectoryPath;

+ (instancetype)sharedFontCache;

- (NSString *)cachedFilePathWithWebURL:(NSURL *)webURL;
- (NSString *)cacheFileAtLocolURL:(NSURL *)locolURL fromWebURL:(NSURL *)webURL;
- (void)cleanCachedFileWithWebURL:(NSURL *)webURL;

@end
