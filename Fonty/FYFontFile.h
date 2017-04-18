//
//  FYFontFile.h
//  Fonty-Demo
//
//  Created by QQQ on 17/3/27.
//  Copyright © 2017年 s2mh. All rights reserved.
//

#import <Foundation/Foundation.h>

@class FYFontModel, UIFont;

typedef NS_ENUM(NSUInteger, FYFontFileDownloadState) {
    FYFontFileDownloadStateToBeDownloaded,
    FYFontFileDownloadStateDownloading,
    FYFontFileDownloadStateSuspended,
    FYFontFileDownloadStateDownloaded,
};

@interface FYFontFile : NSObject <NSCoding>

- (instancetype)initWithSourceURLString:(NSString *)sourceURLString;

@property (nonatomic, copy, readonly) NSString *sourceURLString;
@property (nonatomic, assign, readonly) FYFontFileDownloadState downloadStatus;
@property (nonatomic, assign, readonly) int64_t fileSize;
@property (nonatomic, assign, readonly) int64_t fileDownloadedSize;
@property (nonatomic, assign, readonly) double downloadProgress;
@property (nonatomic, assign, readonly) BOOL fileSizeUnknown;
@property (nonatomic, copy, readonly) NSError *downloadError;
@property (nonatomic, weak, readonly) NSURLSessionDownloadTask *downloadTask;

@property (nonatomic, copy) NSString *localPath;
@property (nonatomic, copy) NSString *fileName;
@property (nonatomic, assign) BOOL registered;
@property (nonatomic, copy) NSArray<FYFontModel *> *fontModels;

- (void)clear;
- (void)resetWithDownloadTask:(NSURLSessionDownloadTask *)downloadTask;

@end

@interface FYFontModel : NSObject <NSCoding>

@property (nonatomic, strong) UIFont *font;
@property (nonatomic, copy) NSString *postScriptName;
@property (nonatomic, weak) FYFontFile *fontFile;

@end
