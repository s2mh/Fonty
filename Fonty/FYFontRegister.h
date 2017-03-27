//
//  FYFontRegister.h
//  Fonty
//
//  Created by 颜为晨 on 9/9/16.
//  Copyright © 2016 颜为晨. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FYFontModel.h"
#import "FYFontFile.h"

extern NSString * const FYFontRegisterErrorPostScriptName;

@interface FYFontRegister : NSObject

+ (instancetype)sharedRegister;

// Return the PostScript name of the font if the registration was successful,
// otherwhise FYFontRegisterErrorPostScriptName.
- (NSArray<FYFontModel *> *)registerFontWithPath:(NSString *)path;
- (BOOL)registerFontInFile:(FYFontFile *)file;
- (void)unregisterFontWithPath:(NSString *)path;

@end
