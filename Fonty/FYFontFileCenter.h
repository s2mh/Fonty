//
//  FYFontFileCenter.h
//  Fonty-Demo
//
//  Created by QQQ on 17/3/27.
//  Copyright © 2017年 s2mh. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FYFontFile.h"

@interface FYFontFileCenter : NSObject

@property (class, copy) NSArray<NSString *> *URLStrings;
@property (class, copy, readonly) NSArray<FYFontFile *> *fontFiles;

@end
