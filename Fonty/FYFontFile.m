//
//  FYFontFile.m
//  Fonty-Demo
//
//  Created by QQQ on 17/3/27.
//  Copyright © 2017年 s2mh. All rights reserved.
//

#import "FYFontFile.h"
#import <objc/runtime.h>

@interface FYFontFile ()

@property (nonatomic, strong) dispatch_semaphore_t semaphore;

@end

@implementation FYFontFile

- (id)copyWithZone:(nullable NSZone *)zone {
    FYFontFile *file = [FYFontFile allocWithZone:zone];
    
    unsigned int propertyCount = 0;
    objc_property_t *properties = class_copyPropertyList([self class], &propertyCount);
    for (unsigned int i = 0; i < propertyCount; i++) {
        objc_property_t property = properties[i];
        NSString *key = [NSString stringWithUTF8String:property_getName(property)];
        if ([key isEqualToString:@"type"]) continue;
        [file setValue:[self valueForKey:key] forKey:key];
    }
    
    return file;
}

- (instancetype)initWithURLString:(NSString *)URLString {
    self = [super init];
    if (self) {
        _fileDownloadURL = [NSURL URLWithString:URLString];
        _downloadTask = nil;
        _fileLocalURL = nil;
        _status = FYFontFileDownloadStatusToBeDownloaded;
        _downloadProgress = 0.0f;
        _downloadError = nil;
        _fileSize = 0.0f;
        _fileSizeUnknown = YES;
        
        _semaphore = dispatch_semaphore_create(1);
    }
    return self;
}

- (void)clear {
    self.fileLocalURL = nil;
    self.downloadTask = nil;
    self.downloadProgress = 0.0;
    self.downloadError = nil;
    self.status = FYFontFileDownloadStatusToBeDownloaded;
}

#pragma mark - Accessor

- (NSURLSessionDownloadTask *)downloadTask {
    dispatch_semaphore_wait(_semaphore, DISPATCH_TIME_FOREVER);
    dispatch_semaphore_signal(_semaphore);
    return _downloadTask;
}

- (void)setDownloadTask:(NSURLSessionDownloadTask *)downloadTask {
    if (_downloadTask != downloadTask) {
        dispatch_semaphore_wait(_semaphore, DISPATCH_TIME_FOREVER);
        _fileDownloadedSize = downloadTask.countOfBytesReceived;
        _fileSize = downloadTask.countOfBytesExpectedToReceive;
        
        switch (downloadTask.state) {
            case NSURLSessionTaskStateRunning: {
                _status = FYFontFileDownloadStatusDownloading;
            } break;
                
            case NSURLSessionTaskStateSuspended: {
                _status = FYFontFileDownloadStatusSuspending;
            } break;
                
            case NSURLSessionTaskStateCanceling: {
                _status = FYFontFileDownloadStatusDownloading;
            } break;
                
            case NSURLSessionTaskStateCompleted: {
                if (downloadTask.error) {
                    _fileDownloadedSize = 0.0f;
                    _status = FYFontFileDownloadStatusToBeDownloaded;
                    _downloadError = downloadTask.error;
                } else {
                    _status = FYFontFileDownloadStatusDownloaded;
                    if (_fileSize == NSURLSessionTransferSizeUnknown) {
                        _fileSize = _fileDownloadedSize;
                    }
                }
            } break;
        }
        
        if (_fileSize > 0) {
            double downloadProgress = (double)_fileDownloadedSize / _fileSize;
            if (downloadProgress > _downloadProgress) {
                _downloadProgress = downloadProgress;
            }
        } else {
            _downloadProgress = 0.0f;
        }
        _fileSizeUnknown = (_fileSize == NSURLSessionTransferSizeUnknown);
        
        _downloadTask = downloadTask;
        
        dispatch_semaphore_signal(_semaphore);
    }
}

@end
