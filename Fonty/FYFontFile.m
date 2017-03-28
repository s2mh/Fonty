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
@property (nonatomic, assign, readwrite) FYFontFileDownloadStatus downloadStatus;
@property (nonatomic, assign, readwrite) double downloadProgress;

@end

@implementation FYFontFile
@synthesize downloadTask = _downloadTask;

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
        _downloadURL = [NSURL URLWithString:URLString];
        _downloadTask = nil;
        _localURL = nil;
        _downloadStatus = FYFontFileDownloadStatusToBeDownloaded;
        _cached = NO;
        _registered = NO;
        _semaphore = dispatch_semaphore_create(1);
    }
    return self;
}

- (void)clear {
    self.localURL = nil;
    self.downloadTask = nil;
    self.cached = NO;
    self.registered = NO;
    self.downloadStatus = FYFontFileDownloadStatusToBeDownloaded;
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
        _downloadTask = downloadTask;
        dispatch_semaphore_signal(_semaphore);
    }
}

- (FYFontFileDownloadStatus)downloadStatus {
    dispatch_semaphore_wait(_semaphore, DISPATCH_TIME_FOREVER);
    if (_downloadTask) {
        switch (_downloadTask.state) {
            case NSURLSessionTaskStateRunning:
            case NSURLSessionTaskStateCanceling: {
                _downloadStatus = FYFontFileDownloadStatusDownloading;
            } break;
                
            case NSURLSessionTaskStateSuspended: {
                _downloadStatus = FYFontFileDownloadStatusSuspending;
            } break;
                
            case NSURLSessionTaskStateCompleted: {
                if (_downloadTask.error) {
                    _downloadStatus = FYFontFileDownloadStatusToBeDownloaded;
                } else {
                    _downloadStatus = FYFontFileDownloadStatusDownloaded;
                }
            } break;
        }
    } else {
        _downloadStatus = FYFontFileDownloadStatusToBeDownloaded;
    }
    
    dispatch_semaphore_signal(_semaphore);
    return _downloadStatus;
}

- (int64_t)fileSize {
    dispatch_semaphore_wait(_semaphore, DISPATCH_TIME_FOREVER);
    dispatch_semaphore_signal(_semaphore);
    return (_downloadStatus == NSURLSessionTaskStateCompleted) ? _downloadTask.countOfBytesReceived : _downloadTask.countOfBytesExpectedToReceive;
}

- (int64_t)fileDownloadedSize {
    dispatch_semaphore_wait(_semaphore, DISPATCH_TIME_FOREVER);
    dispatch_semaphore_signal(_semaphore);
    return _downloadTask.countOfBytesReceived;
}

- (double)downloadProgress {
    dispatch_semaphore_wait(_semaphore, DISPATCH_TIME_FOREVER);
    if (_downloadStatus == NSURLSessionTaskStateCompleted) {
        _downloadProgress = 1.0f;
    } else {
        double downloadProgress = (double)_downloadTask.countOfBytesReceived / _downloadTask.countOfBytesExpectedToReceive;
        if (downloadProgress > _downloadProgress) {
            _downloadProgress = downloadProgress;
        }
    }
    dispatch_semaphore_signal(_semaphore);
    return _downloadProgress;
}

- (BOOL)fileSizeUnknown {
    dispatch_semaphore_wait(_semaphore, DISPATCH_TIME_FOREVER);
    dispatch_semaphore_signal(_semaphore);
    return _downloadTask.countOfBytesExpectedToReceive == NSURLSessionTransferSizeUnknown;
}

- (NSError *)downloadError {
    dispatch_semaphore_wait(_semaphore, DISPATCH_TIME_FOREVER);
    dispatch_semaphore_signal(_semaphore);
    return _downloadTask.error;
}

@end
