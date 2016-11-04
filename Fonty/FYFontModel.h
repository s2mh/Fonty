//
//  FYFontModel.h
//  Fonty
//
//  Created by 颜为晨 on 9/8/16.
//  Copyright © 2016 颜为晨. All rights reserved.
//

#import <Foundation/Foundation.h>


typedef NS_ENUM(NSUInteger, FYFontModelDownloadStatus) {
    FYFontModelDownloadStatusToBeDownloaded,
    FYFontModelDownloadStatusDownloading,
    FYFontModelDownloadStatusSuspending,
    FYFontModelDownloadStatusDownloaded,
    FYFontModelDownloadStatusDeleting
};

@interface FYFontModel : NSObject

@property (nonatomic, assign) FYFontModelDownloadStatus status;

@property (nonatomic, copy) NSString *postScriptName;

@property (nonatomic, copy) NSURL *downloadURL;
@property (nonatomic, copy) NSError *downloadError;

@property (nonatomic, assign) int64_t fileSize;
@property (nonatomic, assign) int64_t fileDownloadedSize;
@property (nonatomic, assign) double downloadProgress;
@property (nonatomic, assign) BOOL fileSizeUnknown;

+ (instancetype)modelWithSessionDownloadTask:(NSURLSessionDownloadTask *)task;
- (void)setWithModel:(FYFontModel *)newModel;

@end
