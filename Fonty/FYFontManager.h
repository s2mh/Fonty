//
//  FYFontManager.h
//  Fonty
//
//  Created by 颜为晨 on 16/7/2.
//  Copyright © 2016年 颜为晨. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class FYFontFile, FYFontModel;

extern NSString *const FYFontFileDownloadingNotification;
extern NSString *const FYFontFileDownloadStateDidChangeNotification;
extern NSString *const FYFontFileDownloadingDidCompleteNotification;
extern NSString *const FYFontFileRegisteringDidCompleteNotification;
extern NSString *const FYFontFileDeletingDidCompleteNotification;
extern NSString *const FYFontFileNotificationUserInfoKey;

@interface FYFontManager : NSObject

+ (void)archive;

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

@property (class, nonatomic, copy) NSArray<NSString *> *fileURLStrings;
@property (class, nonatomic, copy, readonly) NSArray<FYFontFile *> *fontFiles;
@property (class, nonatomic, strong) UIFont *mainFont;

@end
