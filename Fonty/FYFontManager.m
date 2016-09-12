//
//  FYFontManager.m
//  Fonty
//
//  Created by 颜为晨 on 16/7/2.
//  Copyright © 2016年 颜为晨. All rights reserved.
//

#import "FYFontManager.h"
#import "FYFontCache.h"
#import "FYFontRegister.h"
#import "FYFontDownloader.h"
#import "FYFontModel.h"

@interface FYFontManager ()

@property (nonatomic, strong) FYFontCache *fontCache;
@property (nonatomic, strong) FYFontDownloader *fontDownloader;
@property (nonatomic, strong) FYFontRegister *fontRegister;

@property (nonatomic, strong) NSMutableDictionary *postScriptNames; // key = URL.absoluteString, object = postScriptName

@property (nonatomic, strong, readwrite) NSArray<FYFontModel *> *fontModelArray;

@end

@implementation FYFontManager

+ (instancetype)sharedManager {
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
        _fontCache = [FYFontCache sharedFontCache];
        _fontDownloader = [FYFontDownloader sharedDownloader];
        _fontRegister = [FYFontRegister sharedRegister];
        _mainFontIndex = 0;
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(changeModelStatus:)
                                                     name:FYNewFontDownloadNotification
                                                   object:_fontDownloader];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Public

- (UIFont *)fontWithURL:(NSURL *)URL size:(CGFloat)size {
    if (![URL isKindOfClass:NSURL.class]) {
        return [UIFont systemFontOfSize:size];
    }
    
    NSString *postScriptName = [self.postScriptNames objectForKey:URL.absoluteString];
    UIFont *font = [UIFont fontWithName:postScriptName size:size];
    
    if (![font.fontName isEqualToString:postScriptName]) {
        
        if (!postScriptName) {
            // searching postScriptName in cache
            NSString *cachePath = [self.fontCache cachedFilePathWithWebURL:URL];
            if (cachePath) {
                postScriptName = [self.fontRegister registerFontWithPath:cachePath completeBlock:^(NSString *registeredPostScriptName){
                    [self.postScriptNames setObject:registeredPostScriptName forKey:URL.absoluteString];
                    [self.fontModelArray enumerateObjectsUsingBlock:^(FYFontModel * _Nonnull model, NSUInteger idx, BOOL * _Nonnull stop) {
                        if ([model.URL isEqual:URL]) {
                            model.postScriptName = registeredPostScriptName;
                        }
                    }];
                }];
            }
        }
        
        if (postScriptName) {
            // found postScriptName
            font = [UIFont fontWithName:postScriptName size:size];
        }
    }
    
    return font;
}

- (UIFont *)fontWithURLString:(NSString *)URLString size:(CGFloat)size {
    return [self fontWithURL:[NSURL URLWithString:URLString] size:size];
}

- (UIFont *)mainFontOfSize:(CGFloat)size {
    if (self.mainFontIndex < 0 || self.mainFontIndex > self.fontModelArray.count) {
        return [UIFont systemFontOfSize:size];
    }
    FYFontModel *model = [self.fontModelArray objectAtIndex:self.mainFontIndex];
    return [self fontWithURL:model.URL size:size];
}

- (void)downloadFontWithURL:(NSURL *)URL {
    if ([URL isKindOfClass:[NSURL class]]) {
        [self.fontDownloader downloadFontWithURL:URL];
    }
}

- (void)downloadFontWithURLString:(NSString *)URLString {
    [self downloadFontWithURL:[NSURL URLWithString:URLString]];
}

- (void)deleteFontWithURL:(NSURL *)URL completeBlock:(void(^)())completeBlock {
    if ([URL isKindOfClass:[NSURL class]]) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [self.fontCache cleanCachedFileWithWebURL:URL];
            dispatch_async(dispatch_get_main_queue(), ^{
                if (completeBlock) {
                    completeBlock();
                }
            });
        });
    }
}

- (void)deleteFontWithURLString:(NSString *)URLString completeBlock:(void(^)())completeBlock {
    [self deleteFontWithURL:[NSURL URLWithString:URLString] completeBlock:completeBlock];
}

#pragma mark - Notification

- (void)changeModelStatus:(NSNotification *)notif {
    FYFontModel *downloadedModel = [notif.userInfo objectForKey:FYNewFontDownloadNotificationKey];
    for (FYFontModel *model in self.fontModelArray) {
        if ([model.URL isEqual:downloadedModel.URL]) {
            model.status = FYFontModelDownloadStatusDownloaded;
            break;
        }
    }
}

#pragma mark - Accessor

- (void)setFontURLStringArray:(NSArray<NSString *> *)fontURLStringArray {
    _fontURLStringArray = fontURLStringArray;
    
    NSMutableArray *fontModelArray = [NSMutableArray array];
    
    // stand for system default font
    [fontModelArray addObject:[FYFontModel modelWithURL:nil
                                                 status:FYFontModelDownloadStatusDownloaded
                                       downloadProgress:0.0f]];
    
    [fontURLStringArray enumerateObjectsUsingBlock:^(NSString * _Nonnull URLString, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([URLString isKindOfClass:[NSString class]]) {
            NSURL *URL = [NSURL URLWithString:URLString];
            if ([URL isKindOfClass:[NSURL class]]) {
                FYFontModel *model = [FYFontModel modelWithURL:URL
                                                        status:FYFontModelDownloadStatusToBeDownloaded
                                              downloadProgress:0.0f];
                NSString *cachePath = [self.fontCache cachedFilePathWithWebURL:URL];
                if (cachePath) {
                    model.status = FYFontModelDownloadStatusDownloaded;
                }
                [fontModelArray addObject:model];
            }
        }
    }];
    _fontModelArray = [fontModelArray copy];
}

- (NSMutableDictionary *)postScriptNames {
    if (!_postScriptNames) {
        _postScriptNames = [NSMutableDictionary dictionary];
    }
    return _postScriptNames;
}

@end

