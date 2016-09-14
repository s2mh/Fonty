//
//  FYFontCache.m
//  Fonty
//
//  Created by 颜为晨 on 16/7/2.
//  Copyright © 2016年 颜为晨. All rights reserved.
//

#import <CommonCrypto/CommonDigest.h>
#import "FYFontCache.h"
#import "FYFontModel.h"
#import "FYFontDownloader.h"
#import "FYConst.h"

static NSString * const FTFontCacheDirectoryName = @"FTFont";

@interface FYFontCache ()

@property (nonatomic, copy, readwrite) NSString *diskCacheDirectoryPath;
@property (nonatomic, strong) NSMutableDictionary *cachePaths; // key = URLString, object = fontFileName
@property (nonatomic, weak) NSFileManager *fileManager;

@end

@implementation FYFontCache

+ (instancetype)sharedFontCache {
    static id instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [self new];
    });
    return instance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _fileManager = [NSFileManager defaultManager];
    }
    return self;
}

#pragma mark - Public

- (NSString *)cachedFilePathWithWebURL:(NSURL *)webURL {
    NSString *filePath = [self cachedFilePathForWebURLString:webURL.absoluteString];
    if ([self.fileManager fileExistsAtPath:filePath]) {
        return filePath;
    } else {
        return nil;
    }
}

- (NSString *)cacheFileAtLocolURL:(NSURL *)locolURL fromWebURL:(NSURL *)webURL {
    NSString *filePath = [self cachedFilePathForWebURLString:webURL.absoluteString];
    if (![self.fileManager fileExistsAtPath:filePath]) {
        [self.fileManager removeItemAtPath:filePath error:NULL];
    }
    NSURL *docsDirURL = [NSURL fileURLWithPath:filePath];
    [self.fileManager moveItemAtURL:locolURL
                         toURL:docsDirURL
                         error:NULL];
    return filePath;
}

- (void)cleanCachedFileWithWebURL:(NSURL *)webURL {
    NSString *filePath = [self cachedFilePathForWebURLString:webURL.absoluteString];
    [[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];
    dispatch_async(dispatch_get_main_queue(), ^{
        FYFontModel *model = [FYFontModel modelWithURL:webURL
                                                status:FYFontModelDownloadStatusToBeDownloaded
                                      downloadProgress:0.0f];
        NSDictionary *userInfo = @{FYNewFontDownloadNotificationKey:model};
        [[NSNotificationCenter defaultCenter] postNotificationName:FYNewFontDownloadNotification object:self userInfo:userInfo];
    });
}

#pragma mark - Private

- (NSString *)cachedFilePathForWebURLString:(NSString *)URLString {
    NSString *fontFileName = [self.cachePaths objectForKey:URLString];
    if (!fontFileName) {
        const char *str = [URLString UTF8String];
        if (str == NULL) {
            return @"";
        }
        unsigned char r[CC_MD5_DIGEST_LENGTH];
        CC_MD5(str, (CC_LONG)strlen(str), r);
        fontFileName = [NSString stringWithFormat:@"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
                        r[0], r[1], r[2], r[3], r[4], r[5], r[6], r[7], r[8], r[9], r[10],
                        r[11], r[12], r[13], r[14], r[15]];
        [self.cachePaths setObject:fontFileName forKey:URLString];
    }
    
    return [self.diskCacheDirectoryPath stringByAppendingPathComponent:fontFileName];
}


#pragma mark - accessor

- (NSString *)diskCacheDirectoryPath {
    if (!_diskCacheDirectoryPath) {
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
        _diskCacheDirectoryPath = [[paths objectAtIndex:0] stringByAppendingPathComponent:FTFontCacheDirectoryName];
        [self.fileManager createDirectoryAtPath:_diskCacheDirectoryPath
                    withIntermediateDirectories:YES
                                     attributes:nil
                                          error:nil];
    }
    return _diskCacheDirectoryPath;
}

- (NSMutableDictionary *)cachePaths {
    if (!_cachePaths) {
        _cachePaths = [NSMutableDictionary dictionary];
    }
    return _cachePaths;
}

@end
