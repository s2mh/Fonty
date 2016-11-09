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

@property (nonatomic, strong, class) NSMutableDictionary *postScriptNames; // key = URL.absoluteString, object = postScriptName

@property (nonatomic, assign) NSInteger sharedMainFontIndex;
@property (nonatomic, assign) NSInteger sharedMainBoldFontIndex;
@property (nonatomic, assign) NSInteger sharedMainItalicFontIndex;
@property (nonatomic, strong) NSMutableDictionary *sharedPostScriptNames;

@end

@implementation FYFontManager

+ (void)initialize
{
    if (self == [FYFontManager class]) {
        [self setup];
    }
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _sharedMainFontIndex = 0;
        _sharedMainBoldFontIndex = 0;
        _sharedMainItalicFontIndex = 0;
        _sharedPostScriptNames = [NSMutableDictionary dictionary];
    }
    return self;
}

+ (instancetype)sharedManager {
    static FYFontManager *manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (!manager) {
            manager = [self new];
        }
    });
    return manager;
}

+ (void)setup {
    FYFontCache *fontCache = [FYFontCache sharedFontCache];
    fontCache.didCacheFileBlock = ^(NSString *downloadURLString) {
        FYFontModel *model = [FYFontModelCenter fontModelWithURLString:downloadURLString];
        if (model) {
            dispatch_async(dispatch_get_main_queue(), ^{
                model.status = FYFontModelDownloadStatusDownloaded;
                [FYFontManager postNotificationWithModel:model];
            });
        }
    };
    fontCache.didCleanFileBlock = ^(NSString *downloadURLString) {
        FYFontModel *model = [FYFontModelCenter fontModelWithURLString:downloadURLString];
        if (model) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [FYFontManager.postScriptNames removeObjectForKey:model.downloadURL.absoluteString];
                model.downloadProgress = 0.0f;
                model.fileDownloadedSize = 0;
                model.status = FYFontModelDownloadStatusToBeDownloaded;
                [FYFontManager postNotificationWithModel:model];
            });
        }
    };
    
    FYFontDownloader *fontDownloader = [FYFontDownloader sharedDownloader];
    fontDownloader.trackDownloadBlock = ^(FYFontModel *currentModel) {
        FYFontModel *model = [FYFontModelCenter fontModelWithURLString:currentModel.downloadURL.absoluteString];
        if (model) {
            if ((model.status == FYFontModelDownloadStatusDownloading) &&
                (currentModel.status == FYFontModelDownloadStatusDownloading) &&
                (model.fileSizeUnknown || (model.downloadProgress > currentModel.downloadProgress))) {
                return;
            }
            dispatch_async(dispatch_get_main_queue(), ^{                
                [model setWithModel:currentModel];
                [FYFontManager postNotificationWithModel:model];
            });
        }
    };    
}

#pragma mark - Private

+ (void)postNotificationWithModel:(FYFontModel *)model {
    [[NSNotificationCenter defaultCenter] postNotificationName:FYFontStatusNotification
                                                        object:self
                                                      userInfo:@{FYFontStatusNotificationKey:model}];
}

#pragma mark - Public

+ (UIFont *)fontWithURL:(NSURL *)URL size:(CGFloat)size {
    if (![URL isKindOfClass:NSURL.class]) {
        return [self UIFontSystemFontOfSize:size];
    }
    NSString *postScriptName = [FYFontManager.postScriptNames objectForKey:URL.absoluteString];
    UIFont *font = [UIFont fontWithName:postScriptName size:size];
    
    if (![font.fontName isEqualToString:postScriptName]) {
        
        if (!postScriptName) {
            // searching postScriptName in cache
            NSString *cachePath = [[FYFontCache sharedFontCache] cachedFilePathWithDownloadURL:URL];
            if (cachePath) {
                postScriptName = [[FYFontRegister sharedRegister] registerFontWithPath:cachePath completeBlock:^(NSString *registeredPostScriptName){
                    [FYFontManager.postScriptNames setObject:registeredPostScriptName forKey:URL.absoluteString];
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
    if ([URL isKindOfClass:[NSURL class]]) {
        [[FYFontDownloader sharedDownloader] downloadFontWithURL:URL];
    }
}

+ (void)downloadFontWithURLString:(NSString *)URLString {
    [self downloadFontWithURL:[NSURL URLWithString:URLString]];
}

+ (void)cancelDownloadingFontWithURL:(NSURL *)URL {
    if ([URL isKindOfClass:[NSURL class]]) {
        [[FYFontDownloader sharedDownloader] cancelDownloadingFontWithURL:URL];
    }
}

+ (void)cancelDownloadingFontWithURLString:(NSString *)URLString {
    [self cancelDownloadingFontWithURL:[NSURL URLWithString:URLString]];
}

+ (void)deleteFontWithURL:(NSURL *)URL {
    FYFontModel *model = [FYFontModelCenter fontModelWithURLString:URL.absoluteString];
    if (model) {
        model.status = FYFontModelDownloadStatusDeleting;
        [FYFontManager postNotificationWithModel:model];
    }
    if ([URL isKindOfClass:[NSURL class]]) {
        NSString *cachePath = [[FYFontCache sharedFontCache] cachedFilePathWithDownloadURL:URL];
        [[FYFontRegister sharedRegister] unregisterFontWithPath:cachePath completeBlock:^{
            [[FYFontCache sharedFontCache] cleanCachedFileWithDownloadURL:URL];
        }];
    }
}

+ (void)deleteFontWithURLString:(NSString *)URLString {
    [self deleteFontWithURL:[NSURL URLWithString:URLString]];
}

+ (void)pauseDownloadingWithURL:(NSURL *)URL {
    if ([URL isKindOfClass:[NSURL class]]) {
        [[FYFontDownloader sharedDownloader] suspendDownloadWithURL:URL];
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


+ (void)setPostScriptNames:(NSMutableDictionary *)postScriptNames {
    [[FYFontManager sharedManager] setSharedPostScriptNames:postScriptNames];
}

+ (NSMutableDictionary *)postScriptNames {
    return [[FYFontManager sharedManager] sharedPostScriptNames];
}

+ (void)setMainFontIndex:(NSInteger)mainFontIndex {
    [[FYFontManager sharedManager] setSharedMainFontIndex:mainFontIndex];
}

+ (NSInteger)mainFontIndex {
    return [[FYFontManager sharedManager] sharedMainFontIndex];
}

+ (void)setMainBoldFontIndex:(NSInteger)mainBoldFontIndex {
    [[FYFontManager sharedManager] setSharedMainBoldFontIndex:mainBoldFontIndex];
}

+ (NSInteger)mainBoldFontIndex {
    return [[FYFontManager sharedManager] sharedMainBoldFontIndex];
}

+ (void)setMainItalicFontIndex:(NSInteger)mainItalicFontIndex {
    [[FYFontManager sharedManager] setSharedMainItalicFontIndex:mainItalicFontIndex];
}

+ (NSInteger)mainItalicFontIndex {
    return [[FYFontManager sharedManager] sharedMainItalicFontIndex];
}

@end

static IMP __UIFont_systemFontOfSize_method_imp;
static IMP __UIFont_boldSystemFontOfSize_method_imp;
static IMP __UIFont_italicSystemFontOfSize_method_imp;

static inline UIFont *_FY_systemFontOfSize_function(id self, SEL _cmd, CGFloat fontSize)
{
    return [FYFontManager mainFontOfSize:fontSize];
}

static inline UIFont *_FY_boldSystemFontOfSize_function(id self, SEL _cmd, CGFloat fontSize)
{
    return [FYFontManager mainBoldFontOfSize:fontSize];
}

static inline UIFont *_FY_italicSystemFontOfSize_function(id self, SEL _cmd, CGFloat fontSize)
{
    return [FYFontManager mainItalicFontOfSize:fontSize];
}


//static inline UIFont *_UIFont_systemFontOfSize_function(id self, SEL _cmd, CGFloat fontSize)
//{
//    return ((UIFont *(*)(id, SEL, CGFloat))__UIFont_systemFontOfSize_method_imp)(self, _cmd, fontSize);
//}
//
//static inline UIFont *_UIFont_boldSystemFontOfSize_function(id self, SEL _cmd, CGFloat fontSize)
//{
//    return ((UIFont *(*)(id, SEL, CGFloat))__UIFont_boldSystemFontOfSize_method_imp)(self, _cmd, fontSize);
//}
//
//static inline UIFont *_UIFont_italicSystemFontOfSize_function(id self, SEL _cmd, CGFloat fontSize)
//{
//    return ((UIFont *(*)(id, SEL, CGFloat))__UIFont_italicSystemFontOfSize_method_imp)(self, _cmd, fontSize);
//}


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
