//
//  FYFontManager.h
//  Fonty
//
//  Created by 颜为晨 on 16/7/2.
//  Copyright © 2016年 颜为晨. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class FYFontModel;

@interface FYFontManager : NSObject

+ (instancetype)sharedManager;

- (UIFont *)fontWithURL:(NSURL *)URL size:(CGFloat)size;
- (UIFont *)fontWithURLString:(NSString *)URLString size:(CGFloat)size;

- (void)downloadFontWithURL:(NSURL *)URL;
- (void)downloadFontWithURLString:(NSString *)URLString;

- (void)cancelDownloadingFontWithURL:(NSURL *)URL;
- (void)cancelDownloadingFontWithURLString:(NSString *)URLString;

- (void)pauseDownloadingWithURL:(NSURL *)URL;
- (void)pauseDownloadingWithURLString:(NSString *)URLString;

- (void)deleteFontWithURL:(NSURL *)URL;
- (void)deleteFontWithURLString:(NSString *)URLString;


@property (nonatomic, assign) NSInteger mainFontIndex;
@property (nonatomic, assign) NSInteger mainBoldFontIndex;
@property (nonatomic, assign) NSInteger mainItalicFontIndex;

@property (nonatomic, strong) NSArray<NSString *> *fontURLStringArray;
@property (nonatomic, strong) NSArray<NSString *> *boldFontURLStringArray;
@property (nonatomic, strong) NSArray<NSString *> *italicFontURLStringArray;

@property (nonatomic, strong, readonly) NSArray<FYFontModel *> *fontModelArray;
@property (nonatomic, strong, readonly) NSArray<FYFontModel *> *boldFontModelArray;
@property (nonatomic, strong, readonly) NSArray<FYFontModel *> *italicFontModelArray;

- (UIFont *)mainFontOfSize:(CGFloat)size;
- (UIFont *)mainBoldFontOfSize:(CGFloat)size;
- (UIFont *)mainItalicFontOfSize:(CGFloat)size;

@end

@interface FYFontManager (Style)

@property (nonatomic, getter=isUsingFontyStyle) BOOL usingFontyStyle;

- (UIFont *)UIFontSystemFontOfSize:(CGFloat)fontSize;
- (UIFont *)UIFontBoldSystemFontOfSize:(CGFloat)fontSize;
- (UIFont *)UIFontItalicSystemFontOfSize:(CGFloat)fontSize;

@end
