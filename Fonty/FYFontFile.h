//
//  FYFontFile.h
//  Fonty-Demo
//
//  Created by QQQ on 17/3/27.
//  Copyright © 2017年 s2mh. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FYFontModel.h"

typedef NS_ENUM(NSUInteger, FYFontFileDownloadStatus) {
    FYFontFileDownloadStatusToBeDownloaded,
    FYFontFileDownloadStatusDownloading,
    FYFontFileDownloadStatusSuspending,
    FYFontFileDownloadStatusDownloaded,
    FYFontFileDownloadStatusDeleting
};

@interface FYFontFile : NSObject <NSCopying>

@property (nonatomic, assign) FYFontFileDownloadStatus status;

@property (nonatomic, copy) NSURL *fileDownloadURL;
@property (nonatomic, copy) NSURL *fileLocalURL;

@property (nonatomic, assign) int64_t fileSize;
@property (nonatomic, assign) int64_t fileDownloadedSize;
@property (nonatomic, assign) double downloadProgress;
@property (nonatomic, assign) BOOL fileSizeUnknown;

@property (nonatomic, copy) NSError *downloadError;
@property (nonatomic, copy) NSArray<FYFontModel *> *fontModels;
@property (nonatomic, weak) NSURLSessionDownloadTask *downloadTask;

- (instancetype)initWithURLString:(NSString *)URLString;
- (void)clear;

@end
