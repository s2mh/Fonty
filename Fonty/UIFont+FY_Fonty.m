//
//  UIFont+FY_Fonty.m
//  Fonty
//
//  Created by 颜为晨 on 16/7/2.
//  Copyright © 2016年 颜为晨. All rights reserved.
//

#import "UIFont+FY_Fonty.h"

@implementation UIFont (FY_Fonty)

+ (UIFont *)fy_mainFontWithSize:(CGFloat)size {
    return [[FYFontManager mainFont] fontWithSize:size];
}

+ (UIFont *)fy_fontOfModel:(FYFontModel *)model withSize:(CGFloat)size {
    return [model.font fontWithSize:size];
}

@end
