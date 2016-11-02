//
//  FYFontManager.m
//  Fonty
//
//  Created by 颜为晨 on 16/7/2.
//  Copyright © 2016年 颜为晨. All rights reserved.
//

#import <objc/runtime.h>
//#import <objc/objc.h>

#import "FYFontManager.h"
#import "FYFontCache.h"
#import "FYFontRegister.h"
#import "FYFontDownloader.h"
#import "FYFontModel.h"
#import "FYConst.h"

static NSString *const FYMainFontIndexKey = @"FYMainFontIndexKey";

@interface FYFontManager ()

@property (nonatomic, strong) FYFontCache *fontCache;
@property (nonatomic, strong) FYFontDownloader *fontDownloader;
@property (nonatomic, strong) FYFontRegister *fontRegister;

@property (nonatomic, strong) NSMutableDictionary *postScriptNames; // key = URL.absoluteString, object = postScriptName

@property (nonatomic, strong, readwrite) NSArray<FYFontModel *> *fontModelArray;
@property (nonatomic, strong, readwrite) NSArray<FYFontModel *> *boldFontModelArray;
@property (nonatomic, strong, readwrite) NSArray<FYFontModel *> *italicFontModelArray;

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
        _fontCache      = [FYFontCache sharedFontCache];
        _fontDownloader = [FYFontDownloader sharedDownloader];
        _fontRegister   = [FYFontRegister sharedRegister];
        _mainFontIndex  = [[[NSUserDefaults standardUserDefaults] objectForKey:FYMainFontIndexKey] integerValue];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleModelInNotification:)
                                                     name:FYFontStatusNotification
                                                   object:nil];
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
        return [self UIFontSystemFontOfSize:size];
    }
    NSString *postScriptName = [self.postScriptNames objectForKey:URL.absoluteString];
    UIFont *font = [UIFont fontWithName:postScriptName size:size];
    
    if (![font.fontName isEqualToString:postScriptName]) {
        
        if (!postScriptName) {
            // searching postScriptName in cache
            NSString *cachePath = [self.fontCache cachedFilePathWithDownloadURL:URL];
            if (cachePath) {
                postScriptName = [self.fontRegister registerFontWithPath:cachePath completeBlock:^(NSString *registeredPostScriptName){
                    [self.postScriptNames setObject:registeredPostScriptName forKey:URL.absoluteString];
                    [self.fontModelArray enumerateObjectsUsingBlock:^(FYFontModel * _Nonnull model, NSUInteger idx, BOOL * _Nonnull stop) {
                        if ([model.downloadURL isEqual:URL]) {
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
        return [self UIFontSystemFontOfSize:size];
    }
    FYFontModel *model = [self.fontModelArray objectAtIndex:self.mainFontIndex];
    return [self fontWithURL:model.downloadURL size:size];
}

- (UIFont *)mainBoldFontOfSize:(CGFloat)size {
    if (self.mainBoldFontIndex < 0 || self.mainBoldFontIndex > self.boldFontModelArray.count) {
        return [self UIFontBoldSystemFontOfSize:size];
    }
    FYFontModel *model = [self.boldFontModelArray objectAtIndex:self.mainBoldFontIndex];
    return [self fontWithURL:model.downloadURL size:size];
}

- (UIFont *)mainItalicFontOfSize:(CGFloat)size {
    if (self.mainItalicFontIndex < 0 || self.mainItalicFontIndex > self.italicFontModelArray.count) {
        return [self UIFontItalicSystemFontOfSize:size];
    }
    FYFontModel *model = [self.italicFontModelArray objectAtIndex:self.mainItalicFontIndex];
    return [self fontWithURL:model.downloadURL size:size];
}

- (void)downloadFontWithURL:(NSURL *)URL {
    if ([URL isKindOfClass:[NSURL class]]) {
        [self.fontDownloader downloadFontWithURL:URL];
    }
}

- (void)downloadFontWithURLString:(NSString *)URLString {
    [self downloadFontWithURL:[NSURL URLWithString:URLString]];
}

- (void)cancelDownloadingFontWithURL:(NSURL *)URL {
    if ([URL isKindOfClass:[NSURL class]]) {
        [self.fontDownloader cancelDownloadingFontWithURL:URL];
    }
}

- (void)cancelDownloadingFontWithURLString:(NSString *)URLString {
    [self cancelDownloadingFontWithURL:[NSURL URLWithString:URLString]];
}

- (void)deleteFontWithURL:(NSURL *)URL {
    [self.fontModelArray enumerateObjectsUsingBlock:^(FYFontModel * _Nonnull model, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([model.downloadURL isEqual:URL]) {
            model.status = FYFontModelDownloadStatusDeleting;
            if (idx == self.mainFontIndex) {
                self.mainFontIndex = 0;
            }
        }
    }];
    if ([URL isKindOfClass:[NSURL class]]) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSString *cachePath = [self.fontCache cachedFilePathWithDownloadURL:URL];
            [self.fontRegister unregisterFontWithPath:cachePath completeBlock:^{
                [self.fontCache cleanCachedFileWithDownloadURL:URL];
            }];
        });
    }
}

- (void)deleteFontWithURLString:(NSString *)URLString {
    [self deleteFontWithURL:[NSURL URLWithString:URLString]];
}

- (void)pauseDownloadingWithURL:(NSURL *)URL {
    if ([URL isKindOfClass:[NSURL class]]) {
        [self.fontDownloader suspendDownloadWithURL:URL];
    }
}
- (void)pauseDownloadingWithURLString:(NSString *)URLString {
    [self pauseDownloadingWithURL:[NSURL URLWithString:URLString]];
}

#pragma mark - Notification

- (void)handleModelInNotification:(NSNotification *)notification {
    FYFontModel *newModel = [notification.userInfo objectForKey:FYFontStatusNotificationKey];
    for (FYFontModel *model in self.fontModelArray) {
        if ([model.downloadURL isEqual:newModel.downloadURL]) {
            [model setModel:newModel];
            break;
        }
    }
}

#pragma mark - Private

- (NSArray<FYFontModel *> *)assembleModelArrayWithURLStringArray:(NSArray<NSString *> *)fontURLStringArray {
    NSMutableArray *fontModelArray = [NSMutableArray array];
    
    FYFontModel *systemDefaultFontModel = [[FYFontModel alloc] init];
    systemDefaultFontModel.status = FYFontModelDownloadStatusDownloaded;
    systemDefaultFontModel.downloadProgress = 1.0f;
    [fontModelArray addObject:systemDefaultFontModel];
    
    [fontURLStringArray enumerateObjectsUsingBlock:^(NSString * _Nonnull URLString, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([URLString isKindOfClass:[NSString class]]) {
            NSURL *URL = [NSURL URLWithString:URLString];
            if ([URL isKindOfClass:[NSURL class]]) {
                FYFontModel *model = [[FYFontModel alloc] init];
                model.downloadURL = URL;
                NSString *cachePath = [self.fontCache cachedFilePathWithDownloadURL:URL];
                if (cachePath) {
                    model.status = FYFontModelDownloadStatusDownloaded;
                    model.downloadProgress = 1.0f;
                }
                [fontModelArray addObject:model];
            }
        }
    }];
    return [fontModelArray copy];
}

#pragma mark - Accessor

//- (void)setFontURLStringArray:(NSArray<NSString *> *)fontURLStringArray {
//    _fontURLStringArray = fontURLStringArray;
//
//}

- (NSArray<FYFontModel *> *)fontModelArray {
    if (!_fontModelArray) {
        _fontModelArray = [self assembleModelArrayWithURLStringArray:_fontURLStringArray];
    }
    return _fontModelArray;
}

- (NSArray<FYFontModel *> *)boldFontModelArray {
    if (!_boldFontModelArray) {
        _boldFontModelArray = [self assembleModelArrayWithURLStringArray:_boldFontURLStringArray];
    }
    return _boldFontModelArray;
}

- (NSArray<FYFontModel *> *)italicFontModelArray {
    if (!_italicFontModelArray) {
        _italicFontModelArray = [self assembleModelArrayWithURLStringArray:_italicFontURLStringArray];
    }
    return _italicFontModelArray;
}

- (NSMutableDictionary *)postScriptNames {
    if (!_postScriptNames) {
        _postScriptNames = [NSMutableDictionary dictionary];
    }
    return _postScriptNames;
}

- (void)setMainFontIndex:(NSInteger)mainFontIndex {
    if (_mainFontIndex != mainFontIndex) {
        _mainFontIndex = mainFontIndex;
        [[NSUserDefaults standardUserDefaults] setObject:@(_mainFontIndex) forKey:FYMainFontIndexKey];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}

@end


static IMP __UIFont_systemFontOfSize_method_imp;
static IMP __UIFont_boldSystemFontOfSize_method_imp;
static IMP __UIFont_italicSystemFontOfSize_method_imp;

UIFont *_FY_systemFontOfSize_function(id self, SEL _cmd, CGFloat fontSize)
{
    return [[FYFontManager sharedManager] mainFontOfSize:fontSize];
}

UIFont *_FY_boldSystemFontOfSize_function(id self, SEL _cmd, CGFloat fontSize)
{
    return [[FYFontManager sharedManager] mainBoldFontOfSize:fontSize];
}

UIFont *_FY_italicSystemFontOfSize_function(id self, SEL _cmd, CGFloat fontSize)
{
    return [[FYFontManager sharedManager] mainItalicFontOfSize:fontSize];
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

@dynamic usingFontyStyle;

#pragma mark - Public

- (UIFont *)UIFontSystemFontOfSize:(CGFloat)fontSize {
    if (__UIFont_systemFontOfSize_method_imp) {
        return ((UIFont *(*)(id, SEL, CGFloat))__UIFont_systemFontOfSize_method_imp)([UIFont class], @selector(systemFontOfSize:), fontSize);
    } else {
        return [UIFont systemFontOfSize:fontSize];
    }
}

- (UIFont *)UIFontBoldSystemFontOfSize:(CGFloat)fontSize {
    if (__UIFont_boldSystemFontOfSize_method_imp) {
        return ((UIFont *(*)(id, SEL, CGFloat))__UIFont_boldSystemFontOfSize_method_imp)([UIFont class], @selector(boldSystemFontOfSize:), fontSize);
    } else {
        return [UIFont boldSystemFontOfSize:fontSize];
    }
}

- (UIFont *)UIFontItalicSystemFontOfSize:(CGFloat)fontSize {
    if (__UIFont_italicSystemFontOfSize_method_imp) {
        return ((UIFont *(*)(id, SEL, CGFloat))__UIFont_italicSystemFontOfSize_method_imp)([UIFont class], @selector(italicSystemFontOfSize:), fontSize);
    } else {
        return [UIFont italicSystemFontOfSize:fontSize];
    }
}

#pragma mark - Accessor

- (void)setUsingFontyStyle:(BOOL)usingFontyStyle {
    if (usingFontyStyle) {
        [self useFontyStyle];
    } else {
        [self useUIFontStyle];
    }
    objc_setAssociatedObject(self, FYUsingFontyStyleKey, @(usingFontyStyle), OBJC_ASSOCIATION_ASSIGN);
}

- (BOOL)isUsingFontyStyle {
    return [objc_getAssociatedObject(self, FYUsingFontyStyleKey) boolValue];
}

#pragma mark - Private

- (void)useFontyStyle {
    Method systemFontOfSizeMethod       = class_getClassMethod([UIFont class], @selector(systemFontOfSize:));
    Method boldSystemFontOfSizeMethod   = class_getClassMethod([UIFont class], @selector(boldSystemFontOfSize:));
    Method italicSystemFontOfSizeMethod = class_getClassMethod([UIFont class], @selector(italicSystemFontOfSize:));
    
    __UIFont_systemFontOfSize_method_imp       = method_setImplementation(systemFontOfSizeMethod,       (IMP)_FY_systemFontOfSize_function);
    __UIFont_boldSystemFontOfSize_method_imp   = method_setImplementation(boldSystemFontOfSizeMethod,   (IMP)_FY_boldSystemFontOfSize_function);
    __UIFont_italicSystemFontOfSize_method_imp = method_setImplementation(italicSystemFontOfSizeMethod, (IMP)_FY_italicSystemFontOfSize_function);
}

- (void)useUIFontStyle {
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
