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
#import "FYFontModel.h"
#import "FYConst.h"
#import "FYFontModelCenter.h"

static NSString *const FYFontSharedManager = @"FYFontSharedManager";

@interface FYFontManager () <NSCoding>

@property (nonatomic, assign) NSUInteger sharedMainFontIndex;
@property (nonatomic, assign) NSUInteger sharedMainBoldFontIndex;
@property (nonatomic, assign) NSUInteger sharedMainItalicFontIndex;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSString *> *sharedPostScriptNames; // key = URL.absoluteString, object = postScriptName

@property (nonatomic, assign) BOOL sharedUsingFontyStyle;

@end

@implementation FYFontManager

+ (void)initialize
{
    if (self == [FYFontManager class]) {
        [self setup];
        ((void(*)(id, SEL))objc_msgSend)(self, NSSelectorFromString(@"checkStyle"));
    }
}

+ (instancetype)sharedManager {
    static FYFontManager *manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = (FYFontManager *)[[FYFontCache sharedFontCache] objectFromCacheWithFileName:FYFontSharedManager];
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
                NSUInteger index = [FYFontModelCenter indexOfModel:model];
                switch (model.type) {
                    case FYFontTypeFont:
                        if (index == FYFontManager.mainFontIndex) {
                            FYFontManager.mainFontIndex = 0;
                        }
                        break;
                        
                    case FYFontTypeBoldFont:
                        if (index == FYFontManager.mainBoldFontIndex) {
                            FYFontManager.mainBoldFontIndex = 0;
                        }
                        break;
                    case FYFontTypeItalicFont:
                        if (index == FYFontManager.mainItalicFontIndex) {
                            FYFontManager.mainItalicFontIndex = 0;
                        }
                        break;
                }
                [[[FYFontManager sharedManager] sharedPostScriptNames] removeObjectForKey:model.downloadURL.absoluteString];
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

- (instancetype)initWithCoder:(NSCoder *)decoder {
    self = [super init];
    if (!self) {
        return nil;
    }
    self.sharedMainFontIndex       = [decoder decodeIntegerForKey:@"sharedMainFontIndex"];
    self.sharedMainBoldFontIndex   = [decoder decodeIntegerForKey:@"sharedMainBoldFontIndex"];
    self.sharedMainItalicFontIndex = [decoder decodeIntegerForKey:@"sharedMainItalicFontIndex"];
    self.sharedPostScriptNames     = [decoder decodeObjectForKey:@"sharedPostScriptNames"];
    self.sharedUsingFontyStyle     = [decoder decodeBoolForKey:@"sharedUsingFontyStyle"];
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
    [encoder encodeInteger:self.sharedMainFontIndex       forKey:@"sharedMainFontIndex"];
    [encoder encodeInteger:self.sharedMainBoldFontIndex   forKey:@"sharedMainBoldFontIndex"];
    [encoder encodeInteger:self.sharedMainItalicFontIndex forKey:@"sharedMainItalicFontIndex"];
    [encoder encodeObject:self.sharedPostScriptNames      forKey:@"sharedPostScriptNames"];
    [encoder encodeBool:self.sharedUsingFontyStyle        forKey:@"sharedUsingFontyStyle"];
}

#pragma mark - Private

+ (void)postNotificationWithModel:(FYFontModel *)model {
    [[NSNotificationCenter defaultCenter] postNotificationName:FYFontStatusNotification
                                                        object:self
                                                      userInfo:@{FYFontStatusNotificationKey:model}];
}

- (void)cacheSelf {
    [[FYFontCache sharedFontCache] cacheObject:self cacheFileName:FYFontSharedManager];
}

#pragma mark - Public

+ (UIFont *)fontWithURL:(NSURL *)URL size:(CGFloat)size {
    if (![URL isKindOfClass:NSURL.class]) {
        return [self UIFontSystemFontOfSize:size];
    }
    NSMutableDictionary *sharedPostScriptNames = [[FYFontManager sharedManager] sharedPostScriptNames];
    NSString *postScriptName = [sharedPostScriptNames objectForKey:URL.absoluteString];
    UIFont *font = [UIFont fontWithName:postScriptName size:size];
    if (![font.fontName isEqualToString:postScriptName]) {
        NSString *cachePath = [[FYFontCache sharedFontCache] cachedFilePathWithDownloadURL:URL];
        if (cachePath) {
            postScriptName = [[FYFontRegister sharedRegister] registerFontWithPath:cachePath];
            if (postScriptName) {
                font = [UIFont fontWithName:postScriptName size:size];
                [sharedPostScriptNames setObject:postScriptName forKey:URL.absoluteString];
                FYFontModel *model = [FYFontModelCenter fontModelWithURLString:URL.absoluteString];
                if (model) {
                    model.postScriptName = postScriptName;
                }
            }
        }
    }
    return font;
}

+ (UIFont *)fontWithURLString:(NSString *)URLString size:(CGFloat)size {
    return [self fontWithURL:[NSURL URLWithString:URLString] size:size];
}

+ (UIFont *)mainFontOfSize:(CGFloat)size {
    if (FYFontManager.mainFontIndex >= FYFontModelCenter.fontModelArray.count) {
        return [self UIFontSystemFontOfSize:size];
    }
    FYFontModel *model = [FYFontModelCenter.fontModelArray objectAtIndex:FYFontManager.mainFontIndex];
    return [self fontWithURL:model.downloadURL size:size];
}

+ (UIFont *)mainBoldFontOfSize:(CGFloat)size {
    if (FYFontManager.mainBoldFontIndex >= FYFontModelCenter.boldFontModelArray.count) {
        return [self UIFontBoldSystemFontOfSize:size];
    }
    FYFontModel *model = [FYFontModelCenter.boldFontModelArray objectAtIndex:FYFontManager.mainBoldFontIndex];
    return [self fontWithURL:model.downloadURL size:size];
}

+ (UIFont *)mainItalicFontOfSize:(CGFloat)size {
    if (FYFontManager.mainItalicFontIndex >= FYFontModelCenter.italicFontModelArray.count) {
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

+ (void)saveSettins {
    [[FYFontManager sharedManager] cacheSelf];
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

+ (void)setMainFontIndex:(NSUInteger)mainFontIndex {
    [[FYFontManager sharedManager] setSharedMainFontIndex:mainFontIndex];
}

+ (NSUInteger)mainFontIndex {
    return [[FYFontManager sharedManager] sharedMainFontIndex];
}

+ (void)setMainBoldFontIndex:(NSUInteger)mainBoldFontIndex {
    [[FYFontManager sharedManager] setSharedMainBoldFontIndex:mainBoldFontIndex];
}

+ (NSUInteger)mainBoldFontIndex {
    return [[FYFontManager sharedManager] sharedMainBoldFontIndex];
}

+ (void)setMainItalicFontIndex:(NSUInteger)mainItalicFontIndex {
    [[FYFontManager sharedManager] setSharedMainItalicFontIndex:mainItalicFontIndex];
}

+ (NSUInteger)mainItalicFontIndex {
    return [[FYFontManager sharedManager] sharedMainItalicFontIndex];
}

@end

static IMP __UIFont_systemFontOfSize_method_imp;
static IMP __UIFont_boldSystemFontOfSize_method_imp;
static IMP __UIFont_italicSystemFontOfSize_method_imp;

static inline UIFont *_FY_mainFontOfSize_function(id self, SEL _cmd, CGFloat size)
{
    return [FYFontManager mainFontOfSize:size];
}

static inline UIFont *_FY_mainBoldFontOfSize_function(id self, SEL _cmd, CGFloat size)
{
    return [FYFontManager mainBoldFontOfSize:size];
}

static inline UIFont *_FY_mainItalicFontOfSize_function(id self, SEL _cmd, CGFloat size)
{
    return [FYFontManager mainItalicFontOfSize:size];
}

@implementation FYFontManager (Style)

#pragma mark - Public

+ (UIFont *)UIFontSystemFontOfSize:(CGFloat)size {
    if (__UIFont_systemFontOfSize_method_imp) {
        return ((UIFont *(*)(id, SEL, CGFloat))__UIFont_systemFontOfSize_method_imp)([UIFont class], @selector(systemFontOfSize:), size);
    } else {
        return [UIFont systemFontOfSize:size];
    }
}

+ (UIFont *)UIFontBoldSystemFontOfSize:(CGFloat)size {
    if (__UIFont_boldSystemFontOfSize_method_imp) {
        return ((UIFont *(*)(id, SEL, CGFloat))__UIFont_boldSystemFontOfSize_method_imp)([UIFont class], @selector(boldSystemFontOfSize:), size);
    } else {
        return [UIFont boldSystemFontOfSize:size];
    }
}

+ (UIFont *)UIFontItalicSystemFontOfSize:(CGFloat)size {
    if (__UIFont_italicSystemFontOfSize_method_imp) {
        return ((UIFont *(*)(id, SEL, CGFloat))__UIFont_italicSystemFontOfSize_method_imp)([UIFont class], @selector(italicSystemFontOfSize:), size);
    } else {
        return [UIFont italicSystemFontOfSize:size];
    }
}

#pragma mark - Accessor

+ (void)setUsingFontyStyle:(BOOL)usingFontyStyle {
    [FYFontManager sharedManager].sharedUsingFontyStyle = usingFontyStyle;
    [self checkStyle];
}

+ (BOOL)isUsingFontyStyle {
    return [FYFontManager sharedManager].sharedUsingFontyStyle;
}

#pragma mark - Private

+ (void)checkStyle {
    if (self.isUsingFontyStyle) {
        [self useFontyStyle];
    } else {
        [self useUIFontStyle];
    }
}

+ (void)useFontyStyle {
    Method systemFontOfSizeMethod       = class_getClassMethod([UIFont class], @selector(systemFontOfSize:));
    Method boldSystemFontOfSizeMethod   = class_getClassMethod([UIFont class], @selector(boldSystemFontOfSize:));
    Method italicSystemFontOfSizeMethod = class_getClassMethod([UIFont class], @selector(italicSystemFontOfSize:));
    
    __UIFont_systemFontOfSize_method_imp       = method_setImplementation(systemFontOfSizeMethod,       (IMP)_FY_mainFontOfSize_function);
    __UIFont_boldSystemFontOfSize_method_imp   = method_setImplementation(boldSystemFontOfSizeMethod,   (IMP)_FY_mainBoldFontOfSize_function);
    __UIFont_italicSystemFontOfSize_method_imp = method_setImplementation(italicSystemFontOfSizeMethod, (IMP)_FY_mainItalicFontOfSize_function);
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
