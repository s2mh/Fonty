//
//  FYFontModel.h
//  Fonty
//
//  Created by 颜为晨 on 9/8/16.
//  Copyright © 2016 颜为晨. All rights reserved.
//

#import <Foundation/Foundation.h>

@class UIFont;

typedef NS_ENUM(NSUInteger, FYFontType) {
    FYFontTypeFont = 0,
    FYFontTypeBoldFont,
    FYFontTypeItalicFont,
};

@interface FYFontModel : NSObject

@property (nonatomic, assign) FYFontType type;
@property (nonatomic, strong) UIFont *font;
@property (nonatomic, copy) NSString *postScriptName;

@end
