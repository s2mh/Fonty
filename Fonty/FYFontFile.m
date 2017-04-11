//
//  FYFontFile.m
//  Fonty-Demo
//
//  Created by QQQ on 17/3/27.
//  Copyright © 2017年 s2mh. All rights reserved.
//

#import <objc/runtime.h>

#import "FYFontFile.h"
#import "FYFontModel.h"
#import "FYFontRegister.h"

@interface FYFontFile ()

@property (nonatomic, strong) dispatch_semaphore_t semaphore;

@property (nonatomic, assign, readwrite) FYFontFileDownloadStatus downloadStatus;
@property (nonatomic, assign, readwrite) int64_t fileSize;
@property (nonatomic, assign, readwrite) int64_t fileDownloadedSize;
@property (nonatomic, assign, readwrite) double downloadProgress;
@property (nonatomic, assign, readwrite) BOOL fileSizeUnknown;
@property (nonatomic, copy, readwrite) NSError *downloadError;

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

- (instancetype)init {
    self = [super init];
    if (self) {
        _downloadURLString = nil;
        _localURLString = nil;
        _downloadStatus = FYFontFileDownloadStatusToBeDownloaded;
        _registered = NO;
        _semaphore = dispatch_semaphore_create(1);
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)decoder {
    self = [super init];
    if (!self) {
        return nil;
    }
    _downloadURLString = [decoder decodeObjectForKey:@"_downloadURLString"];
    _localURLString = [decoder decodeObjectForKey:@"_localURLString"];
    _downloadStatus = [decoder decodeIntegerForKey:@"_downloadStatus"];
    _fileSize = [decoder decodeInt64ForKey:@"_fileSize"];
    _downloadProgress = [decoder decodeDoubleForKey:@"_downloadProgress"];
    _registered = NO;
    _semaphore = dispatch_semaphore_create(1);
    if (_downloadStatus == FYFontFileDownloadStatusDownloaded) {
        _registered = [FYFontRegister registerFontInFile:self];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
    [encoder encodeObject:_downloadURLString forKey:@"_downloadURLString"];
    [encoder encodeObject:_localURLString forKey:@"_localURLString"];
    if ((_downloadStatus == FYFontFileDownloadStatusSuspending) || (_downloadStatus == FYFontFileDownloadStatusDownloading)) {
        _downloadStatus = FYFontFileDownloadStatusToBeDownloaded;
    }
    [encoder encodeInteger:_downloadStatus forKey:@"_downloadStatus"];
    [encoder encodeInt64:_fileSize forKey:@"_fileSize"];
    [encoder encodeDouble:_downloadProgress forKey:@"_downloadProgress"];
    [encoder encodeBool:_registered forKey:@"_registered"];
    [encoder encodeObject:_fontModels forKey:@"_fontModels"];
}

- (void)clear {
    self.localURLString = nil;
    self.registered = NO;
    self.downloadProgress = 0.0;
    self.downloadStatus = FYFontFileDownloadStatusToBeDownloaded;
}

#pragma mark - Accessor

- (void)setDownloadTask:(NSURLSessionDownloadTask *)downloadTask {
    dispatch_semaphore_wait(_semaphore, DISPATCH_TIME_FOREVER);
    _downloadTask = downloadTask;
    switch (downloadTask.state) {
        case NSURLSessionTaskStateRunning:
        case NSURLSessionTaskStateCanceling: {
            _downloadStatus = FYFontFileDownloadStatusDownloading;
        } break;
            
        case NSURLSessionTaskStateSuspended: {
            _downloadStatus = FYFontFileDownloadStatusSuspending;
        } break;
            
        case NSURLSessionTaskStateCompleted: {
            if (downloadTask.error) {
                _downloadStatus = FYFontFileDownloadStatusToBeDownloaded;
            } else {
                _downloadStatus = FYFontFileDownloadStatusDownloaded;
            }
        } break;
    }
    
    _fileSize = (_downloadStatus == NSURLSessionTaskStateCompleted) ? downloadTask.countOfBytesReceived : downloadTask.countOfBytesExpectedToReceive;
    _fileDownloadedSize = downloadTask.countOfBytesReceived;
    
    if (_downloadStatus == FYFontFileDownloadStatusDownloaded) {
        _downloadProgress = 1.0;
    } else {
        double downloadProgress = (double)downloadTask.countOfBytesReceived / downloadTask.countOfBytesExpectedToReceive;
        if (downloadProgress > _downloadProgress) {
            _downloadProgress = downloadProgress;
        }
    }
    
    _fileSizeUnknown = (downloadTask.countOfBytesExpectedToReceive == NSURLSessionTransferSizeUnknown);
    _downloadError = downloadTask.error;
    
    dispatch_semaphore_signal(_semaphore);
}

@end
