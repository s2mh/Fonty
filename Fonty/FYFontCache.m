//
//  FYFontCache.m
//  Fonty
//
//  Created by 颜为晨 on 16/7/2.
//  Copyright © 2016年 颜为晨. All rights reserved.
//

#import <CommonCrypto/CommonDigest.h>
#import "FYFontCache.h"
#import "FYFontFile.h"
#import "FYFontManager.h"

static NSString * const FYFontCacheDirectoryName = @"FYFont";

@implementation FYFontCache

#pragma mark - Public

+ (BOOL)cacheObject:(id)object fileName:(NSString *)fileName {
    NSString *cachePath = [[self diskCacheDirectoryPath] stringByAppendingPathComponent:fileName];
    NSData *cacheData = [NSKeyedArchiver archivedDataWithRootObject:object];
    return [cacheData writeToFile:cachePath atomically:YES];
}

+ (id)objectFromCacheWithFileName:(NSString *)fileName {
    NSString *cachePath = [[self diskCacheDirectoryPath] stringByAppendingPathComponent:fileName];
    NSData *cacheData = [NSData dataWithContentsOfFile:cachePath];
    if (cacheData) {
        id obj = [NSKeyedUnarchiver unarchiveObjectWithData:cacheData];
        return obj;
    } else {
        return nil;
    }
}

+ (void)cacheFile:(FYFontFile *)file
       atLocation:(NSURL *)location
completionHandler:(void(^)(NSError *))completionHandler {
    NSString *fileLocationName = [self filePathForSourceURLString:file.sourceURLString];
    NSString *filePath = [[self diskCacheDirectoryPath] stringByAppendingPathComponent:fileLocationName];
    NSError *error = nil;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    if ([fileManager fileExistsAtPath:filePath] && ![fileManager removeItemAtPath:filePath error:&error]) {
        goto completion;
    }
    
    if ([fileManager moveItemAtPath:location.path
                             toPath:filePath
                              error:&error]) {
        file.fileName = fileLocationName;
        file.localPath = filePath;
    }
    
completion:
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:FYFontFileDownloadingDidCompleteNotification
                                                            object:nil
                                                          userInfo:@{FYFontFileNotificationUserInfoKey:file}];
    });
    
    if (completionHandler) {
        completionHandler(error);
    }
}

+ (void)cleanCachedFile:(FYFontFile *)file completionHandler:(void(^)(NSError *))completionHandler {
    NSError *error = nil;
    [[NSFileManager defaultManager] removeItemAtPath:file.localPath error:&error];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:FYFontFileDeletingDidCompleteNotification
                                                            object:nil
                                                          userInfo:@{FYFontFileNotificationUserInfoKey:file}];
    });
    
    if (completionHandler) {
        completionHandler(error);
    }
}

+ (NSString *)diskCacheDirectoryPath {
    static NSString *_diskCacheDirectoryPath;
    if (!_diskCacheDirectoryPath) {
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
        
        _diskCacheDirectoryPath = [[paths objectAtIndex:0] stringByAppendingPathComponent:FYFontCacheDirectoryName];
        NSError *error = nil;
        [fileManager createDirectoryAtPath:_diskCacheDirectoryPath
               withIntermediateDirectories:YES
                                attributes:nil
                                     error:&error];
    }
    return _diskCacheDirectoryPath;
}

#pragma mark - Private

+ (NSString *)filePathForSourceURLString:(NSString *)URLString {
    const char *str = [URLString UTF8String];
    if (str == NULL) {
        return @"";
    }
    unsigned char r[CC_MD5_DIGEST_LENGTH];
    CC_MD5(str, (CC_LONG)strlen(str), r);
    return [NSString stringWithFormat:@"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
            r[0], r[1], r[2], r[3], r[4], r[5], r[6], r[7], r[8], r[9], r[10],
            r[11], r[12], r[13], r[14], r[15]];
}

@end
