//
//  FYFontRegister.h
//  Fonty
//
//  Created by 颜为晨 on 9/9/16.
//  Copyright © 2016 颜为晨. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString * const FYFontRegisterErrorPostScriptName;

@interface FYFontRegister : NSObject

+ (instancetype)sharedRegister;

// Return the PostScript name of the font if the registration was successful,
// otherwhise FYFontRegisterErrorPostScriptName.
- (NSString *)registerFontWithPath:(NSString *)path;

- (void)unregisterFontWithPath:(NSString *)path;

@end
