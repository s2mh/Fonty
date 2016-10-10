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

- (UIFont *)mainFontOfSize:(CGFloat)size;

@property (nonatomic, strong) NSArray<NSString *> *fontURLStringArray;
@property (nonatomic, assign) NSInteger mainFontIndex;
@property (nonatomic, strong, readonly) NSArray<FYFontModel *> *fontModelArray;

- (void)downloadFontWithURL:(NSURL *)URL;
- (void)downloadFontWithURLString:(NSString *)URLString;

- (void)cancelDownloadingFontWithURL:(NSURL *)URL;
- (void)cancelDownloadingFontWithURLString:(NSString *)URLString;

- (void)pauseDownloadingWithURL:(NSURL *)URL;
- (void)pauseDownloadingWithURLString:(NSString *)URLString;

- (void)deleteFontWithURL:(NSURL *)URL;
- (void)deleteFontWithURLString:(NSString *)URLString;

@end
