//
//  FYFontManager.m
//  Fonty
//
//  Created by 颜为晨 on 16/7/2.
//  Copyright © 2016年 颜为晨. All rights reserved.
//

#import <objc/runtime.h>

#import "FYFontManager.h"
#import "FYFontCache.h"
#import "FYFontRegister.h"
#import "FYFontDownloader.h"
#import "FYFontModel.h"
#import "FYConst.h"
#import "FYFontModelCenter.h"

static NSString *const FYFontSharedManager = @"FYFontSharedManager";

@interface FYFontManager ()

@property (nonatomic, strong) FYFontCache *fontCache;
@property (nonatomic, strong) FYFontDownloader *fontDownloader;
@property (nonatomic, strong) FYFontRegister *fontRegister;

@property (nonatomic, strong) NSMutableDictionary *postScriptNames; // key = URL.absoluteString, object = postScriptName

@end

@implementation FYFontManager

static const void *FYMainFontIndexKey;
static const void *FYMainBoldFontIndexKey;
static const void *FYMainItalicFontIndexKey;

+ (instancetype)sharedManager {
    static id instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[FYFontCache sharedFontCache] objectFromCacheWithFileName:FYFontSharedManager];
        if (!instance) {
            instance = [self new];
        }
        [instance setup];
    });
    return instance;
}

- (void)setup {
    _fontCache = [FYFontCache sharedFontCache];
    _fontCache.didCacheFileBlock = ^(NSString *downloadURLString) {
        FYFontModel *model = [FYFontModelCenter fontModelWithURLString:downloadURLString];
        if (model) {
            model.status = FYFontModelDownloadStatusDownloaded;
            [FYFontManager postNotificationOnMainThreadWithModel:model];
        }
    };
    _fontCache.didCleanFileBlock = ^(NSString *downloadURLString) {
        FYFontModel *model = [FYFontModelCenter fontModelWithURLString:downloadURLString];
        if (model) {
            model.status = FYFontModelDownloadStatusToBeDownloaded;
            [FYFontManager postNotificationOnMainThreadWithModel:model];
        }
    };
    
    _fontDownloader = [FYFontDownloader sharedDownloader];
    _fontDownloader.trackDownloadBlock = ^(FYFontModel *currentModel) {
        FYFontModel *model = [FYFontModelCenter fontModelWithURLString:currentModel.downloadURL.absoluteString];
        if (model) {
            if ((model.status == FYFontModelDownloadStatusDownloading) &&
                (currentModel.status == FYFontModelDownloadStatusDownloading) &&
                (currentModel.fileSizeUnknown || (model.downloadProgress > currentModel.downloadProgress))) {
                return;
            }
            [model setWithModel:currentModel];
            [FYFontManager postNotificationOnMainThreadWithModel:currentModel];
        }
    };
    _fontRegister = [FYFontRegister sharedRegister];
    
    _postScriptNames = [NSMutableDictionary dictionary];
}

- (void)dealloc
{
    [_fontCache cacheObject:self cacheFileName:FYFontSharedManager];
}

#pragma mark - Private

+ (void)postNotificationOnMainThreadWithModel:(FYFontModel *)model {
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:FYFontStatusNotification
                                                            object:nil
                                                          userInfo:@{FYFontStatusNotificationKey:model}];
    });
}

#pragma mark - Public

+ (UIFont *)fontWithURL:(NSURL *)URL size:(CGFloat)size {
    if (![URL isKindOfClass:NSURL.class]) {
        return [self UIFontSystemFontOfSize:size];
    }
    FYFontManager *manager = [FYFontManager sharedManager];
    NSString *postScriptName = [manager.postScriptNames objectForKey:URL.absoluteString];
    UIFont *font = [UIFont fontWithName:postScriptName size:size];
    
    if (![font.fontName isEqualToString:postScriptName]) {
        
        if (!postScriptName) {
            // searching postScriptName in cache
            NSString *cachePath = [manager.fontCache cachedFilePathWithDownloadURL:URL];
            if (cachePath) {
                postScriptName = [manager.fontRegister registerFontWithPath:cachePath completeBlock:^(NSString *registeredPostScriptName){
                    [manager.postScriptNames setObject:registeredPostScriptName forKey:URL.absoluteString];
                    FYFontModel *model = [FYFontModelCenter fontModelWithURLString:URL.absoluteString];
                    if (model) {
                        model.postScriptName = registeredPostScriptName;
                    }
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

+ (UIFont *)fontWithURLString:(NSString *)URLString size:(CGFloat)size {
    return [self fontWithURL:[NSURL URLWithString:URLString] size:size];
}

+ (UIFont *)mainFontOfSize:(CGFloat)size {
    if (FYFontManager.mainFontIndex < 0 || FYFontManager.mainFontIndex >= FYFontModelCenter.fontModelArray.count) {
        return [self UIFontSystemFontOfSize:size];
    }
    FYFontModel *model = [FYFontModelCenter.fontModelArray objectAtIndex:FYFontManager.mainFontIndex];
    return [self fontWithURL:model.downloadURL size:size];
}

+ (UIFont *)mainBoldFontOfSize:(CGFloat)size {
    if (FYFontManager.mainBoldFontIndex < 0 || FYFontManager.mainBoldFontIndex >= FYFontModelCenter.boldFontModelArray.count) {
        return [self UIFontBoldSystemFontOfSize:size];
    }
    FYFontModel *model = [FYFontModelCenter.boldFontModelArray objectAtIndex:FYFontManager.mainBoldFontIndex];
    return [self fontWithURL:model.downloadURL size:size];
}

+ (UIFont *)mainItalicFontOfSize:(CGFloat)size {
    if (FYFontManager.mainItalicFontIndex < 0 || FYFontManager.mainItalicFontIndex >= FYFontModelCenter.italicFontModelArray.count) {
        return [self UIFontItalicSystemFontOfSize:size];
    }
    FYFontModel *model = [FYFontModelCenter.italicFontModelArray objectAtIndex:FYFontManager.mainItalicFontIndex];
    return [self fontWithURL:model.downloadURL size:size];
}

+ (void)downloadFontWithURL:(NSURL *)URL {
    FYFontManager *manager = [FYFontManager sharedManager];
    if ([URL isKindOfClass:[NSURL class]]) {
        [manager.fontDownloader downloadFontWithURL:URL];
    }
}

+ (void)downloadFontWithURLString:(NSString *)URLString {
    [self downloadFontWithURL:[NSURL URLWithString:URLString]];
}

+ (void)cancelDownloadingFontWithURL:(NSURL *)URL {
    FYFontManager *manager = [FYFontManager sharedManager];
    if ([URL isKindOfClass:[NSURL class]]) {
        [manager.fontDownloader cancelDownloadingFontWithURL:URL];
    }
}

+ (void)cancelDownloadingFontWithURLString:(NSString *)URLString {
    [self cancelDownloadingFontWithURL:[NSURL URLWithString:URLString]];
}

+ (void)deleteFontWithURL:(NSURL *)URL {
    FYFontManager *manager = [FYFontManager sharedManager];
    [FYFontModelCenter.fontModelArray enumerateObjectsUsingBlock:^(FYFontModel * _Nonnull model, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([model.downloadURL isEqual:URL]) {
            model.status = FYFontModelDownloadStatusDeleting;
            if (idx == FYFontManager.mainFontIndex) {
                FYFontManager.mainFontIndex = 0;
            }
        }
    }];
    if ([URL isKindOfClass:[NSURL class]]) {
        NSString *cachePath = [manager.fontCache cachedFilePathWithDownloadURL:URL];
        [manager.fontRegister unregisterFontWithPath:cachePath completeBlock:^{
            [manager.fontCache cleanCachedFileWithDownloadURL:URL];
        }];
    }
}

+ (void)deleteFontWithURLString:(NSString *)URLString {
    [self deleteFontWithURL:[NSURL URLWithString:URLString]];
}

+ (void)pauseDownloadingWithURL:(NSURL *)URL {
    FYFontManager *manager = [FYFontManager sharedManager];
    if ([URL isKindOfClass:[NSURL class]]) {
        [manager.fontDownloader suspendDownloadWithURL:URL];
    }
}

+ (void)pauseDownloadingWithURLString:(NSString *)URLString {
    [self pauseDownloadingWithURL:[NSURL URLWithString:URLString]];
}

+ (void)setFontURLStringArray:(NSArray<NSString *> *)fontURLStringArray {
    FYFontModelCenter.fontURLStringArray = fontURLStringArray;
}

+ (void)setBoldFontURLStringArray:(NSArray<NSString *> *)boldFontURLStringArray {
    FYFontModelCenter.boldFontURLStringArray = boldFontURLStringArray;
}

+ (void)setItalicFontURLStringArray:(NSArray<NSString *> *)italicFontURLStringArray {
    FYFontModelCenter.italicFontURLStringArray = italicFontURLStringArray;
}

#pragma mark - Accessor

+ (NSMutableArray<FYFontModel *> *)fontModelArray {
    return FYFontModelCenter.fontModelArray;
}

+ (NSMutableArray<FYFontModel *> *)boldFontModelArray {
    return FYFontModelCenter.boldFontModelArray;
}

+ (NSMutableArray<FYFontModel *> *)italicFontModelArray {
    return FYFontModelCenter.italicFontModelArray;
}

+ (void)setMainFontIndex:(NSInteger)mainFontIndex {
    objc_setAssociatedObject(self, FYMainFontIndexKey, @(mainFontIndex), OBJC_ASSOCIATION_ASSIGN);
}

+ (NSInteger)mainFontIndex {
    return [objc_getAssociatedObject(self, FYMainFontIndexKey) integerValue];
}

+ (void)setMainBoldFontIndex:(NSInteger)mainBoldFontIndex {
    objc_setAssociatedObject(self, FYMainBoldFontIndexKey, @(mainBoldFontIndex), OBJC_ASSOCIATION_ASSIGN);
}

+ (NSInteger)mainBoldFontIndex {
    return [objc_getAssociatedObject(self, FYMainBoldFontIndexKey) integerValue];
}

+ (void)setMainItalicFontIndex:(NSInteger)mainItalicFontIndex {
    objc_setAssociatedObject(self, FYMainItalicFontIndexKey, @(mainItalicFontIndex), OBJC_ASSOCIATION_ASSIGN);
}

+ (NSInteger)mainItalicFontIndex {
    return [objc_getAssociatedObject(self, FYMainItalicFontIndexKey) integerValue];
}

@end

static IMP __UIFont_systemFontOfSize_method_imp;
static IMP __UIFont_boldSystemFontOfSize_method_imp;
static IMP __UIFont_italicSystemFontOfSize_method_imp;

UIFont *_FY_systemFontOfSize_function(id self, SEL _cmd, CGFloat fontSize)
{
    return [FYFontManager mainFontOfSize:fontSize];
}

UIFont *_FY_boldSystemFontOfSize_function(id self, SEL _cmd, CGFloat fontSize)
{
    return [FYFontManager mainBoldFontOfSize:fontSize];
}

UIFont *_FY_italicSystemFontOfSize_function(id self, SEL _cmd, CGFloat fontSize)
{
    return [FYFontManager mainItalicFontOfSize:fontSize];
}


UIFont *_UIFont_systemFontOfSize_function(id self, SEL _cmd, CGFloat fontSize)
{
    return ((UIFont *(*)(id, SEL, CGFloat))__UIFont_systemFontOfSize_method_imp)(self, _cmd, fontSize);
}

UIFont *_UIFont_boldSystemFontOfSize_function(id self, SEL _cmd, CGFloat fontSize)
{
    return ((UIFont *(*)(id, SEL, CGFloat))__UIFont_boldSystemFontOfSize_method_imp)(self, _cmd, fontSize);
}

UIFont *_UIFont_italicSystemFontOfSize_function(id self, SEL _cmd, CGFloat fontSize)
{
    return ((UIFont *(*)(id, SEL, CGFloat))__UIFont_italicSystemFontOfSize_method_imp)(self, _cmd, fontSize);
}


@implementation FYFontManager (Style)

static const void *FYUsingFontyStyleKey;

#pragma mark - Public

+ (UIFont *)UIFontSystemFontOfSize:(CGFloat)fontSize {
    if (__UIFont_systemFontOfSize_method_imp) {
        return ((UIFont *(*)(id, SEL, CGFloat))__UIFont_systemFontOfSize_method_imp)([UIFont class], @selector(systemFontOfSize:), fontSize);
    } else {
        return [UIFont systemFontOfSize:fontSize];
    }
}

+ (UIFont *)UIFontBoldSystemFontOfSize:(CGFloat)fontSize {
    if (__UIFont_boldSystemFontOfSize_method_imp) {
        return ((UIFont *(*)(id, SEL, CGFloat))__UIFont_boldSystemFontOfSize_method_imp)([UIFont class], @selector(boldSystemFontOfSize:), fontSize);
    } else {
        return [UIFont boldSystemFontOfSize:fontSize];
    }
}

+ (UIFont *)UIFontItalicSystemFontOfSize:(CGFloat)fontSize {
    if (__UIFont_italicSystemFontOfSize_method_imp) {
        return ((UIFont *(*)(id, SEL, CGFloat))__UIFont_italicSystemFontOfSize_method_imp)([UIFont class], @selector(italicSystemFontOfSize:), fontSize);
    } else {
        return [UIFont italicSystemFontOfSize:fontSize];
    }
}

#pragma mark - Accessor

+ (void)setUsingFontyStyle:(BOOL)usingFontyStyle {
    if (usingFontyStyle) {
        [self useFontyStyle];
    } else {
        [self useUIFontStyle];
    }
    objc_setAssociatedObject(self, FYUsingFontyStyleKey, @(usingFontyStyle), OBJC_ASSOCIATION_ASSIGN);
}

+ (BOOL)isUsingFontyStyle {
    return [objc_getAssociatedObject(self, FYUsingFontyStyleKey) boolValue];
}

#pragma mark - Private

+ (void)useFontyStyle {
    Method systemFontOfSizeMethod       = class_getClassMethod([UIFont class], @selector(systemFontOfSize:));
    Method boldSystemFontOfSizeMethod   = class_getClassMethod([UIFont class], @selector(boldSystemFontOfSize:));
    Method italicSystemFontOfSizeMethod = class_getClassMethod([UIFont class], @selector(italicSystemFontOfSize:));
    
    __UIFont_systemFontOfSize_method_imp       = method_setImplementation(systemFontOfSizeMethod,       (IMP)_FY_systemFontOfSize_function);
    __UIFont_boldSystemFontOfSize_method_imp   = method_setImplementation(boldSystemFontOfSizeMethod,   (IMP)_FY_boldSystemFontOfSize_function);
    __UIFont_italicSystemFontOfSize_method_imp = method_setImplementation(italicSystemFontOfSizeMethod, (IMP)_FY_italicSystemFontOfSize_function);
}

+ (void)useUIFontStyle {
    if (!__UIFont_systemFontOfSize_method_imp ||
        !__UIFont_boldSystemFontOfSize_method_imp ||
        !__UIFont_italicSystemFontOfSize_method_imp) {
        return;
    }
    
    Method systemFontOfSizeMethod       = class_getClassMethod([UIFont class], @selector(systemFontOfSize:));
    Method boldSystemFontOfSizeMethod   = class_getClassMethod([UIFont class], @selector(boldSystemFontOfSize:));
    Method italicSystemFontOfSizeMethod = class_getClassMethod([UIFont class], @selector(italicSystemFontOfSize:));
    
    method_setImplementation(systemFontOfSizeMethod,       __UIFont_systemFontOfSize_method_imp);
    method_setImplementation(boldSystemFontOfSizeMethod,   __UIFont_boldSystemFontOfSize_method_imp);
    method_setImplementation(italicSystemFontOfSizeMethod, __UIFont_italicSystemFontOfSize_method_imp);
}

@end
