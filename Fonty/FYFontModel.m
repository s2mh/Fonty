//
//  FYFontModel.m
//  Fonty
//
//  Created by 颜为晨 on 9/8/16.
//  Copyright © 2016 颜为晨. All rights reserved.
//

#import <UIKit/UIFont.h>
#import "FYFontModel.h"
#import "FYFontRegister.h"

@implementation FYFontModel

- (instancetype)initWithCoder:(NSCoder *)decoder {
    self = [super init];
    if (!self) {
        return nil;
    }
    _postScriptName = [decoder decodeObjectForKey:@"_postScriptName"];
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
    [encoder encodeObject:_postScriptName forKey:@"_postScriptName"];
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"%@", self.postScriptName];
}

@end
