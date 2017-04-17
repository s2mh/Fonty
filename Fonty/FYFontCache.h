//
//  FYFontCache.h
//  Fonty
//
//  Created by 颜为晨 on 16/7/2.
//  Copyright © 2016年 颜为晨. All rights reserved.
//

#import <Foundation/Foundation.h>

@class FYFontFile;

@interface FYFontCache : NSObject

+ (BOOL)cacheObject:(id)object fileName:(NSString *)fileName;
+ (id)objectFromCacheWithFileName:(NSString *)fileName;

+ (void)cacheFile:(FYFontFile *)file atLocation:(NSURL *)location completionHandler:(void(^)(NSError *error))completionHandler ;
+ (void)cleanCachedFile:(FYFontFile *)file completionHandler:(void(^)(NSError *error))completionHandler;

+ (NSString *)diskCacheDirectoryPath;

@end
