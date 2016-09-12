//
//  UIFont+FY_Fonty.m
//  Fonty
//
//  Created by 颜为晨 on 16/7/2.
//  Copyright © 2016年 颜为晨. All rights reserved.
//

#import "UIFont+FY_Fonty.h"

@implementation UIFont (FY_Fonty)

+ (UIFont *)fy_mainFontOfSize:(CGFloat)size {
    return [[FYFontManager sharedManager] mainFontOfSize:size];
}

+ (UIFont *)fy_fontWithURL:(NSURL *)URL size:(CGFloat)size {
    return [[FYFontManager sharedManager] fontWithURL:URL size:size];
}

+ (UIFont *)fy_fontWithURLString:(NSString *)URLString size:(CGFloat)size {
    return [[FYFontManager sharedManager] fontWithURLString:URLString size:size];
}

@end
