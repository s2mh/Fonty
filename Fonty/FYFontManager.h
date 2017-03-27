//
//  FYFontManager.h
//  Fonty
//
//  Created by 颜为晨 on 16/7/2.
//  Copyright © 2016年 颜为晨. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import "FYFontModel.h"
#import "FYFontFile.h"
#import "FYConst.h"

@class FYFontModel;

@interface FYFontManager : NSObject

+ (void)saveSettins;


+ (void)downloadFontFile:(FYFontFile *)file;
+ (void)cancelDownloadingFontFile:(FYFontFile *)file;
+ (void)pauseDownloadingFile:(FYFontFile *)file;
+ (void)deleteFontFile:(FYFontFile *)file;

@property (class, weak) FYFontModel *mainFontModel;

@end
