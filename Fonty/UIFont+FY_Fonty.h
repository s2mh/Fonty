//
//  UIFont+FY_Fonty.h
//  Fonty
//
//  Created by 颜为晨 on 16/7/2.
//  Copyright © 2016年 颜为晨. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Fonty.h"

@interface UIFont (FY_Fonty)

+ (UIFont *)fy_mainFontWithSize:(CGFloat)size;
+ (UIFont *)fy_fontOfModel:(FYFontModel *)model withSize:(CGFloat)size;

@end
