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
        _URL = nil;
        _status = FYFontModelDownloadStatusToBeDownloaded;
        _downloadProgress = 0.0f;
        _postScriptName = @"";
        _fileSizeUnknown = NO;
        _downloadError = nil;
    }
    return self;
}

+ (instancetype)modelWithSessionDownloadTask:(NSURLSessionDownloadTask *)task {
    FYFontModel *model = [[FYFontModel alloc] init];
    model.URL = task.originalRequest.URL;
    
    if (task.countOfBytesExpectedToReceive == NSURLSessionTransferSizeUnknown) {
        model.fileSizeUnknown = YES;
    } else {
        model.downloadProgress = (double)task.countOfBytesReceived / task.countOfBytesExpectedToReceive;
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
            if (task.error) {
                model.downloadProgress = 0.0f;
                model.status = FYFontModelDownloadStatusToBeDownloaded;
                model.downloadError = task.error;
            } else {
                model.downloadProgress = 1.0f;
                model.status = FYFontModelDownloadStatusDownloaded;
            }
        }
            break;
    }
    return model;
}

- (void)setModel:(FYFontModel *)newModel {
    if (newModel.status == FYFontModelDownloadStatusDownloading && !self.fileSizeUnknown && self.downloadProgress > newModel.downloadProgress) {
        return;
    }    
    self.URL                = newModel.URL;
    self.status             = newModel.status;
    self.downloadProgress   = newModel.downloadProgress;
    self.fileSizeUnknown    = newModel.fileSizeUnknown;
    self.postScriptName     = newModel.postScriptName;
    self.fileSizeUnknown    = newModel.fileSizeUnknown;
    self.downloadError      = newModel.downloadError;
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
