//
//  FYFontModel.m
//  Fonty
//
//  Created by 颜为晨 on 9/8/16.
//  Copyright © 2016 颜为晨. All rights reserved.
//

#import "FYFontModel.h"

@implementation FYFontModel

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.URL = nil;
        self.status = FYFontModelDownloadStatusToBeDownloaded;
        self.downloadProgress = 0.0f;
        self.postScriptName = @"";
        self.fileSizeUnknown = NO;
    }
    return self;
}

+ (instancetype)modelWithSessionDownloadTask:(NSURLSessionDownloadTask *)task {
    FYFontModel *model = [[FYFontModel alloc] init];
    
    model.URL = task.originalRequest.URL;
    if (task.countOfBytesExpectedToReceive == 0) {
        model.downloadProgress = 0.0f;
    } else {
        if (task.countOfBytesExpectedToReceive != NSURLSessionTransferSizeUnknown) {
            model.downloadProgress = (double)task.countOfBytesReceived / task.countOfBytesExpectedToReceive;
        } else {
            model.fileSizeUnknown = YES;
        }
    }
    
    switch (task.state) {
        case NSURLSessionTaskStateRunning: {
            model.status = FYFontModelDownloadStatusDownloading;
        } break;
            
        case NSURLSessionTaskStateSuspended: {
            model.status = FYFontModelDownloadStatusSuspending;
        } break;
            
        case NSURLSessionTaskStateCanceling: {
            model.status = FYFontModelDownloadStatusDownloading;
        } break;
            
        default: {
            NSLog(@"countOfBytesReceived %lld, %lld", task.countOfBytesReceived, task.countOfBytesExpectedToReceive);
            NSLog(@"\n");
            if (model.downloadProgress == 1.0f) {
                model.status = FYFontModelDownloadStatusDownloaded;
            } else {
                model.downloadProgress = 0.0f;
                model.status = FYFontModelDownloadStatusToBeDownloaded;
            }
        }
            break;
    }
    
    return model;
}

- (NSString *)description
{
    if (self.URL) {
        return self.URL.absoluteString;
    } else {
        return @"system default font";
    }
}

@end
