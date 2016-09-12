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
    FYFontModelDownloadStatusDownloaded,
    FYFontModelDownloadStatusDeleting
};

@interface FYFontModel : NSObject

@property (nonatomic, copy) NSURL *URL;
@property (nonatomic, assign) FYFontModelDownloadStatus status;
@property (nonatomic, assign) float downloadProgress;
@property (nonatomic, copy) NSString *postScriptName;

+ (instancetype)modelWithURL:(NSURL *)URL
                      status:(FYFontModelDownloadStatus)status
            downloadProgress:(float)downloadProgress;

@end
