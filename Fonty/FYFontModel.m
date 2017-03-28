//
//  FYFontModel.m
//  Fonty
//
//  Created by 颜为晨 on 9/8/16.
//  Copyright © 2016 颜为晨. All rights reserved.
//

#import <objc/runtime.h>
#import <objc/message.h>
#import "FYFontModel.h"

@implementation FYFontModel

- (instancetype)init
{
    self = [super init];
    if (self) {
        _type = FYFontTypeFont;
        _font = nil;
        _postScriptName = @"";
    }
    return self;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"%@", self.postScriptName];
}

@end
