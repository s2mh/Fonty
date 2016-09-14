//
//  FYFontRegister.h
//  Fonty
//
//  Created by 颜为晨 on 9/9/16.
//  Copyright © 2016 颜为晨. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FYFontRegister : NSObject

+ (instancetype)sharedRegister;

- (NSString *)registerFontWithPath:(NSString *)path completeBlock:(void(^)(NSString *registeredPostScriptName))completeBlock;
- (void)unregisterFontWithPath:(NSString *)path completeBlock:(void(^)())completeBlock;

@end
