//
//  FYFontManager.m
//  Fonty
//
//  Created by 颜为晨 on 16/7/2.
//  Copyright © 2016年 颜为晨. All rights reserved.
//

#import <objc/runtime.h>
#import <objc/message.h>

#import "FYFontManager.h"
#import "FYFontCache.h"
#import "FYFontRegister.h"
#import "FYFontDownloader.h"

static NSString *const FYFontSharedManagerName = @"FYFontSharedManagerName";

@interface FYFontManager () <NSCoding>

@property (nonatomic, copy) NSArray<NSString *> *URLStrings;
@property (nonatomic, copy) NSArray<FYFontFile *> *fontFiles;

@property (nonatomic, strong) FYFontFile *mainFontFile;
@property (nonatomic, copy) NSString *mainFontName;
@property (nonatomic, strong) UIFont *mainFont;

@end

@implementation FYFontManager

+ (void)initialize
{
    if (self == [FYFontManager class]) {
        [self setup];
    }
}

+ (instancetype)sharedManager {
    static FYFontManager *manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = (FYFontManager *)[[FYFontCache sharedFontCache] objectFromCacheWithFileName:FYFontSharedManagerName];
        if (!manager) {
            manager = [self new];
        }
    });
    return manager;
}

+ (void)setup {
    FYFontCache *fontCache = [FYFontCache sharedFontCache];
    fontCache.didCacheFileBlock = ^(FYFontFile *file) {
        if (file && [FYFontRegister registerFontInFile:file]) {
            [FYFontManager postNotificationWithFile:file];
        }
    };
    
    FYFontDownloader *fontDownloader = [FYFontDownloader sharedDownloader];
    fontDownloader.timeoutInterval = 180.0;
    fontDownloader.trackDownloadBlock = ^(FYFontFile *file) {
        if (file) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [FYFontManager postNotificationWithFile:file];
            });
        }
    };
}

+ (UIFont *)mainFont {
    FYFontManager *sharedManager = [FYFontManager sharedManager];
    if (sharedManager.mainFont) {
        return sharedManager.mainFont;
    } else {
        UIFont *font = [UIFont fontWithName:sharedManager.mainFontName size:10.0f];
        if (sharedManager.mainFontName && ![font.fontName isEqualToString:sharedManager.mainFontName] && sharedManager.mainFontFile.downloadStatus == FYFontFileDownloadStatusDownloaded) {
            [FYFontRegister registerFontInFile:sharedManager.mainFontFile];
            font = [UIFont fontWithName:sharedManager.mainFontName size:10.0f];
        }
        return font;
    }
}

+ (void)setMainFont:(UIFont *)mainFont {
    FYFontManager *sharedManager = [FYFontManager sharedManager];
    sharedManager.mainFont = mainFont;
    sharedManager.mainFontName = mainFont.fontName;
}

- (instancetype)initWithCoder:(NSCoder *)decoder {
    self = [super init];
    if (!self) {
        return nil;
    }
    _URLStrings = [decoder decodeObjectForKey:@"URLStrings"];
    _fontFiles = [decoder decodeObjectForKey:@"fontFiles"];
    _mainFontName = [decoder decodeObjectForKey:@"mainFontName"];
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
    [encoder encodeObject:_URLStrings forKey:@"URLStrings"];
    [encoder encodeObject:_fontFiles forKey:@"fontFiles"];
    [encoder encodeObject:_mainFontName forKey:@"mainFontName"];
}

#pragma mark - Private

+ (void)postNotificationWithFile:(FYFontFile *)file {
    [[NSNotificationCenter defaultCenter] postNotificationName:FYFontStatusNotification
                                                        object:self
                                                      userInfo:@{FYFontStatusNotificationKey:file}];
}

+ (void)saveSettins {
    [[FYFontManager sharedManager] cacheSelf];
}

- (void)cacheSelf {
    [[FYFontCache sharedFontCache] cacheObject:self fileName:FYFontSharedManagerName];
}

+ (void)downloadFontFile:(FYFontFile *)file {
    [[FYFontDownloader sharedDownloader] downloadFontFile:file];
}

+ (void)cancelDownloadingFontFile:(FYFontFile *)file {
    [[FYFontDownloader sharedDownloader] cancelDownloadingFile:file];
}

+ (void)pauseDownloadingFile:(FYFontFile *)file {
    [[FYFontDownloader sharedDownloader] suspendDownloadFile:file];
}

+ (void)deleteFontFile:(FYFontFile *)file {
    [FYFontRegister unregisterFontInFile:file];
    [[FYFontCache sharedFontCache] cleanCachedFile:file];
}

+ (BOOL)registerFontFile:(FYFontFile *)file {
    return [FYFontRegister registerFontInFile:file];
}

+ (NSArray<NSString *> *)fileURLStrings {
    return [[FYFontManager sharedManager] URLStrings];
}

+ (void)setFileURLStrings:(NSArray<NSString *> *)fileURLStrings {
    FYFontManager *sharedManager = [FYFontManager sharedManager];
    if (fileURLStrings != sharedManager.URLStrings) {
        dispatch_semaphore_t semaphore = dispatch_semaphore_create(1);
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
        
        NSArray<FYFontFile *> *oldFontFiles = sharedManager.fontFiles;
        NSArray<NSString *> *oldDownloadURLStrings = [oldFontFiles valueForKey:@"downloadURLString"];
        
        NSMutableArray<FYFontFile *> *fontFiles = [NSMutableArray array];
        [fileURLStrings enumerateObjectsUsingBlock:^(NSString * _Nonnull URLString, NSUInteger idx, BOOL * _Nonnull stop) {
            NSUInteger index = [oldDownloadURLStrings indexOfObject:URLString];
            if (!oldDownloadURLStrings || index == NSNotFound) {
                FYFontFile *file = [[FYFontFile alloc] init];
                file.downloadURLString = URLString;
                [fontFiles addObject:file];
            } else {
                FYFontFile *file = oldFontFiles[index];
                [fontFiles addObject:file];
            }
        }];
        
        sharedManager.fontFiles = fontFiles;
        sharedManager.URLStrings = fileURLStrings;
        dispatch_semaphore_signal(semaphore);
    }
}

+ (NSArray<FYFontFile *> *)fontFiles {
    return [[FYFontManager sharedManager] fontFiles];
}

@end
