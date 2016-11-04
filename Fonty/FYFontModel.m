//
//  FYFontModel.m
//  Fonty
//
//  Created by 颜为晨 on 9/8/16.
//  Copyright © 2016 颜为晨. All rights reserved.
//

#import <objc/runtime.h>
#import <objc/message.h>
#import "FYFontModel.h"

@implementation FYFontModel

- (instancetype)init
{
    self = [super init];
    if (self) {
        _downloadURL = nil;
        _status = FYFontModelDownloadStatusToBeDownloaded;
        _downloadProgress = 0.0f;
        _postScriptName = @"";
        _fileSize = 0.0f;
        _fileSizeUnknown = YES;
        _downloadError = nil;
    }
    return self;
}

+ (instancetype)modelWithSessionDownloadTask:(NSURLSessionDownloadTask *)task {
    FYFontModel *model = [[FYFontModel alloc] init];
    model.downloadURL = task.originalRequest.URL;
    
    model.fileDownloadedSize = task.countOfBytesReceived;
    model.fileSize = task.countOfBytesExpectedToReceive;
    
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
                model.fileDownloadedSize = 0.0f;
                model.status = FYFontModelDownloadStatusToBeDownloaded;
                model.downloadError = task.error;
            } else {
                model.status = FYFontModelDownloadStatusDownloaded;
                if (model.fileSize == NSURLSessionTransferSizeUnknown) {
                    model.fileSize = model.fileDownloadedSize;
                }
            }
        } break;
    }
    
    if (model.fileSize > 0) {
        model.downloadProgress = (double)model.fileDownloadedSize / model.fileSize;
    } else {
        model.downloadProgress = 0.0f;
    }
    model.fileSizeUnknown = ((model.fileSize == NSURLSessionTransferSizeUnknown) || (model.fileSize == 0.0f));
    
    return model;
}

- (void)setWithModel:(FYFontModel *)newModel {
    unsigned int propertyCount = 0;
    objc_property_t *properties = class_copyPropertyList([self class], &propertyCount);
    for (unsigned int i = 0; i < propertyCount; i++) {
        objc_property_t property = properties[i];
        NSString *key = [NSString stringWithUTF8String:property_getName(property)];
        [self setValue:[newModel valueForKey:key] forKey:key];
    }
}

- (NSString *)description
{
    if (self.downloadURL) {
        return self.downloadURL.absoluteString;
    } else {
        return @"Default Font";
    }
}

@end
