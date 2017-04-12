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

@class FYFontModel;

extern NSString *const FYFontFileDidChangeNotification;
extern NSString *const FYFontFileDidChangeNotificationUserInfoKey;

@interface FYFontManager : NSObject

+ (void)saveSettins;

+ (void)downloadFontFile:(FYFontFile *)file;
+ (void)downloadFontFile:(FYFontFile *)file
                progress:(void(^)(FYFontFile *file))progress
       completionHandler:(void(^)(NSError *error))completionHandler;
+ (void)cancelDownloadingFontFile:(FYFontFile *)file;
+ (void)pauseDownloadingFile:(FYFontFile *)file;
+ (void)deleteFontFile:(FYFontFile *)file;
+ (void)deleteFontFile:(FYFontFile *)file
     completionHandler:(void(^)(NSError *error))completionHandler;

+ (BOOL)registerFontFile:(FYFontFile *)file;

@property (nonatomic, class, copy) NSArray<NSString *> *fileURLStrings;
@property (nonatomic, class, copy, readonly) NSArray<FYFontFile *> *fontFiles;
@property (nonatomic, class, strong) UIFont *mainFont;

@end
