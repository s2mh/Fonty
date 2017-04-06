//
//  FYFontCache.h
//  Fonty
//
//  Created by 颜为晨 on 16/7/2.
//  Copyright © 2016年 颜为晨. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FYFontFile.h"

@interface FYFontCache : NSObject

@property (nonatomic, copy, readonly) NSString *diskCacheDirectoryPath;

+ (instancetype)sharedFontCache;

- (BOOL)cacheObject:(id)object fileName:(NSString *)fileName;
- (instancetype)objectFromCacheWithFileName:(NSString *)fileName;

- (BOOL)cacheFile:(FYFontFile *)file;
- (BOOL)cleanCachedFile:(FYFontFile *)file;


@property (nonatomic, copy) void(^didCleanFileBlock)(FYFontFile *file);
@property (nonatomic, copy) void(^didCacheFileBlock)(FYFontFile *file);

@end
