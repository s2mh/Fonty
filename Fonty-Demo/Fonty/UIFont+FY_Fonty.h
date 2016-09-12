//
//  UIFont+FY_Fonty.h
//  Fonty
//
//  Created by 颜为晨 on 16/7/2.
//  Copyright © 2016年 颜为晨. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FYFontManager.h"

@interface UIFont (FY_Fonty)
+ (UIFont *)fy_mainFontOfSize:(CGFloat)size;
+ (UIFont *)fy_fontWithURL:(NSURL *)URL size:(CGFloat)size;
+ (UIFont *)fy_fontWithURLString:(NSString *)URLString size:(CGFloat)size;

@end
