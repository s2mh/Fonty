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
};

@interface FYFontFile : NSObject <NSCopying>

@property (nonatomic, copy) NSURL *downloadURL;
@property (nonatomic, copy) NSURL *localURL;

@property (nonatomic, assign) BOOL cached;
@property (nonatomic, assign) BOOL registered;

@property (nonatomic, assign, readonly) FYFontFileDownloadStatus downloadStatus;
@property (nonatomic, assign, readonly) int64_t fileSize;
@property (nonatomic, assign, readonly) int64_t fileDownloadedSize;
@property (nonatomic, assign, readonly) double downloadProgress;
@property (nonatomic, assign, readonly) BOOL fileSizeUnknown;
@property (nonatomic, copy, readonly) NSError *downloadError;

@property (nonatomic, copy) NSArray<FYFontModel *> *fontModels;
@property (atomic, strong) NSURLSessionDownloadTask *downloadTask;

- (instancetype)initWithURLString:(NSString *)URLString;
- (void)clear;

@end
