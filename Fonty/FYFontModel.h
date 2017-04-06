//
//  FYFontModel.h
//  Fonty
//
//  Created by 颜为晨 on 9/8/16.
//  Copyright © 2016 颜为晨. All rights reserved.
//

#import <Foundation/Foundation.h>

@class UIFont, FYFontFile;

@interface FYFontModel : NSObject <NSCoding>

@property (nonatomic, strong) UIFont *font;
@property (nonatomic, copy) NSString *postScriptName;
@property (nonatomic, weak) FYFontFile *fontFile;

@end
