//
//  FYFontFile.h
//  Fonty-Demo
//
//  Created by QQQ on 17/3/27.
//  Copyright © 2017年 s2mh. All rights reserved.
//

#import <Foundation/Foundation.h>

@class FYFontModel;

typedef NS_ENUM(NSUInteger, FYFontFileDownloadStatus) {
    FYFontFileDownloadStatusToBeDownloaded,
    FYFontFileDownloadStatusDownloading,
    FYFontFileDownloadStatusSuspending,
    FYFontFileDownloadStatusDownloaded,
};

@interface FYFontFile : NSObject <NSCoding, NSCopying>

@property (nonatomic, copy) NSString *downloadURLString;
@property (nonatomic, copy) NSString *localURLString;
@property (nonatomic, copy) NSArray<FYFontModel *> *fontModels;
@property (nonatomic, weak) NSURLSessionDownloadTask *downloadTask;
@property (nonatomic, assign) BOOL registered;

@property (nonatomic, assign, readonly) FYFontFileDownloadStatus downloadStatus;
@property (nonatomic, assign, readonly) int64_t fileSize;
@property (nonatomic, assign, readonly) int64_t fileDownloadedSize;
@property (nonatomic, assign, readonly) double downloadProgress;
@property (nonatomic, assign, readonly) BOOL fileSizeUnknown;
@property (nonatomic, copy, readonly) NSError *downloadError;

- (void)clear;

@end
