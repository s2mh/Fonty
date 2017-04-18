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
#import "FYFontFile.h"
#import "FYFontCache.h"
#import "FYFontRegister.h"
#import "FYFontDownloader.h"

NSString *const FYFontFileDownloadingNotification = @"FYFontFileDownloadingNotification";
NSString *const FYFontFileDownloadStateDidChangeNotification = @"FYFontFileDownloadStateDidChangeNotification";
NSString *const FYFontFileDownloadingDidCompleteNotification = @"FYFontFileDownloadingDidCompleteNotification";
NSString *const FYFontFileRegisteringDidCompleteNotification = @"FYFontFileRegisteringDidCompleteNotification";
NSString *const FYFontFileDeletingDidCompleteNotification = @"FYFontFileDeletingDidCompleteNotification";
NSString *const FYFontFileNotificationUserInfoKey = @"FYFontFileNotificationUserInfoKey";
static NSString *const FYFontSharedManagerName = @"FYFontSharedManagerName";

@interface FYFontManager () <NSCoding>

@property (nonatomic, strong) FYFontDownloader *downloader;
@property (nonatomic, copy) NSArray<NSString *> *URLStrings;
@property (nonatomic, copy) NSArray<FYFontFile *> *fontFiles;
@property (nonatomic, weak) FYFontFile *mainFontFile;
@property (nonatomic, copy) NSString *mainFontName;
@property (nonatomic, strong) UIFont *mainFont;

@end

@implementation FYFontManager

+ (instancetype)sharedManager {
    static FYFontManager *manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = (FYFontManager *)[FYFontCache objectFromCacheWithFileName:FYFontSharedManagerName];
        if (!manager) {
            manager = [self new];
        }
    });
    return manager;
}

- (instancetype)initWithCoder:(NSCoder *)decoder {
    self = [super init];
    if (!self) {
        return nil;
    }
    _URLStrings = [decoder decodeObjectForKey:@"_URLStrings"];
    _fontFiles = [decoder decodeObjectForKey:@"_fontFiles"];
    _mainFontName = [decoder decodeObjectForKey:@"_mainFontName"];
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
    [encoder encodeObject:_URLStrings forKey:@"_URLStrings"];
    [encoder encodeObject:_fontFiles forKey:@"_fontFiles"];
    [encoder encodeObject:_mainFontName forKey:@"_mainFontName"];
}

#pragma mark - Private

- (void)archiveSelf {
    [FYFontCache cacheObject:self fileName:FYFontSharedManagerName];
}

#pragma mark - Public

+ (void)archive {
    [[FYFontManager sharedManager] archiveSelf];
}

+ (void)downloadFontFile:(FYFontFile *)file {
    [self downloadFontFile:file progress:nil completionHandler:nil];
}

+ (void)downloadFontFile:(FYFontFile *)file progress:(void(^)(FYFontFile *file))progress completionHandler:(void(^)(NSError *error))completionHandler {
    FYFontManager *sharedManager = [FYFontManager sharedManager];
    [sharedManager.downloader downloadFontFile:file
                                      progress:^(FYFontFile *file) {
                                          dispatch_async(dispatch_get_main_queue(), ^{
                                              if (progress) {
                                                  progress(file);
                                              }
                                          });
                                      }
                             completionHandler:^(NSError *error) {
                                 if (!error) {
                                     [FYFontRegister registerFontInFile:file];
                                 }
                                 dispatch_async(dispatch_get_main_queue(), ^{
                                     if (completionHandler) {
                                         completionHandler(error);
                                     }
                                 });
                             }];
}

+ (void)cancelDownloadingFontFile:(FYFontFile *)file {
    FYFontManager *sharedManager = [FYFontManager sharedManager];
    [sharedManager.downloader cancelDownloadingFile:file];
}

+ (void)pauseDownloadingFile:(FYFontFile *)file {
    FYFontManager *sharedManager = [FYFontManager sharedManager];
    [sharedManager.downloader suspendDownloadFile:file];
}


+ (void)deleteFontFile:(FYFontFile *)file{
    [self deleteFontFile:file completionHandler:nil];
}

+ (void)deleteFontFile:(FYFontFile *)file completionHandler:(void(^)(NSError *))completionHandler {
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(queue, ^{
        [FYFontRegister unregisterFontInFile:file];
        [FYFontCache cleanCachedFile:file completionHandler:^(NSError *error) {
            UIFont *mainFont = [FYFontManager mainFont];
            for (FYFontModel *model in file.fontModels) {
                if ([model.font isEqual:mainFont]) {
                    [FYFontManager setMainFont:nil];
                    break;
                }
            }
            [file clear];
            dispatch_async(dispatch_get_main_queue(), ^{
                if (completionHandler) {
                    completionHandler(error);
                }
            });
        }];
    });
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
        NSArray<FYFontFile *> *oldFontFiles = sharedManager.fontFiles;
        NSArray<NSString *> *oldSourceURLStrings = [oldFontFiles valueForKey:@"sourceURLString"];
        
        NSMutableArray<FYFontFile *> *fontFiles = [NSMutableArray array];
        [fileURLStrings enumerateObjectsUsingBlock:^(NSString * _Nonnull URLString, NSUInteger idx, BOOL * _Nonnull stop) {
            NSUInteger index = [oldSourceURLStrings indexOfObject:URLString];
            if (!oldSourceURLStrings || index == NSNotFound) {
                FYFontFile *file = [[FYFontFile alloc] initWithSourceURLString:URLString];
                [fontFiles addObject:file];
            } else {
                FYFontFile *file = oldFontFiles[index];
                [fontFiles addObject:file];
                if ((file.downloadStatus == FYFontFileDownloadStateDownloaded) &&
                    [file.fileName isEqualToString:sharedManager.mainFontName]) {
                    sharedManager.mainFontFile = file;
                }
            }
        }];
        
        sharedManager.fontFiles = fontFiles;
        sharedManager.URLStrings = fileURLStrings;
    }
}

+ (NSArray<FYFontFile *> *)fontFiles {
    return [[FYFontManager sharedManager] fontFiles];
}

#pragma mark - Accessor

+ (UIFont *)mainFont {
    FYFontManager *sharedManager = [FYFontManager sharedManager];
    if (!sharedManager.mainFont) {
        if (sharedManager.mainFontFile) {
            [FYFontRegister registerFontInFile:sharedManager.mainFontFile];
            sharedManager.mainFont = [UIFont fontWithName:sharedManager.mainFontName size:17.0];
        } else {
            sharedManager.mainFont = [UIFont systemFontOfSize:17.0];
        }
    }
    return sharedManager.mainFont;
}

+ (void)setMainFont:(UIFont *)mainFont {
    FYFontManager *sharedManager = [FYFontManager sharedManager];
    sharedManager.mainFont = mainFont;
    sharedManager.mainFontName = mainFont.fontName;
}

- (FYFontDownloader *)downloader {
    if (!_downloader) {
        _downloader = [[FYFontDownloader alloc] init];
    }
    return _downloader;
}

@end
