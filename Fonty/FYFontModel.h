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

@property (nonatomic, copy) NSURL *URL;
@property (nonatomic, assign) FYFontModelDownloadStatus status;
@property (nonatomic, assign) double downloadProgress;
@property (nonatomic, copy) NSString *postScriptName;
@property (nonatomic, assign) BOOL fileSizeUnknown;
@property (nonatomic, copy) NSError *downloadError;

+ (instancetype)modelWithSessionDownloadTask:(NSURLSessionDownloadTask *)task;
- (void)setModel:(FYFontModel *)newModel;

@end
