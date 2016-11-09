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
    return [FYFontManager mainFontOfSize:size];
}

+ (UIFont *)fy_mainBoldFontOfSize:(CGFloat)size {
    return [FYFontManager mainBoldFontOfSize:size];
}

+ (UIFont *)fy_mainItalicFontOfSize:(CGFloat)size {
    return [FYFontManager mainItalicFontOfSize:size];
}

+ (UIFont *)fy_fontWithURL:(NSURL *)URL size:(CGFloat)size {
    return [FYFontManager fontWithURL:URL size:size];
}

+ (UIFont *)fy_fontWithURLString:(NSString *)URLString size:(CGFloat)size {
    return [FYFontManager fontWithURLString:URLString size:size];
}

@end
