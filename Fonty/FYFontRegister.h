//
//  FYFontRegister.h
//  Fonty
//
//  Created by 颜为晨 on 9/9/16.
//  Copyright © 2016 颜为晨. All rights reserved.
//

#import <Foundation/Foundation.h>

@class FYFontFile;

extern NSString * const FYFontRegisterErrorPostScriptName;

@interface FYFontRegister : NSObject

+ (BOOL)registerFontInFile:(FYFontFile *)file;
+ (BOOL)unregisterFontInFile:(FYFontFile *)file;

@end
