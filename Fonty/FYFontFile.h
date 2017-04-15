//
//  FYFontFile.h
//  Fonty-Demo
//
//  Created by QQQ on 17/3/27.
//  Copyright © 2017年 s2mh. All rights reserved.
//

#import <Foundation/Foundation.h>

@class FYFontModel;

typedef NS_ENUM(NSUInteger, FYFontFileDownloadState) {
    FYFontFileDownloadStateToBeDownloaded,
    FYFontFileDownloadStateDownloading,
    FYFontFileDownloadStateSuspending,
    FYFontFileDownloadStateDownloaded,
};

@interface FYFontFile : NSObject <NSCoding>

- (instancetype)initWithSourceURLString:(NSString *)sourceURLString;

@property (nonatomic, copy) NSString *sourceURLString;
@property (nonatomic, copy) NSString *localURLString;
@property (nonatomic, copy) NSArray<FYFontModel *> *fontModels;
@property (nonatomic, assign) BOOL registered;
@property (nonatomic, assign, readonly) FYFontFileDownloadState downloadStatus;
@property (nonatomic, assign, readonly) int64_t fileSize;
@property (nonatomic, assign, readonly) int64_t fileDownloadedSize;
@property (nonatomic, assign, readonly) double downloadProgress;
@property (nonatomic, assign, readonly) BOOL fileSizeUnknown;
@property (nonatomic, copy, readonly) NSError *downloadError;
@property (nonatomic, weak, readonly) NSURLSessionDownloadTask *downloadTask;

- (void)clear;
- (void)resetWithDownloadTask:(NSURLSessionDownloadTask *)downloadTask;

@end
