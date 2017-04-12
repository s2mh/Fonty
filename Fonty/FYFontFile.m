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
#import "FYFontCache.h"
#import "FYFontRegister.h"
#import "FYFontDownloader.h"
#import "FYFontManager.h"

@interface FYFontFile ()

@property (nonatomic, assign, readwrite) FYFontFileDownloadState downloadStatus;
@property (nonatomic, assign, readwrite) int64_t fileSize;
@property (nonatomic, assign, readwrite) int64_t fileDownloadedSize;
@property (nonatomic, assign, readwrite) double downloadProgress;
@property (nonatomic, assign, readwrite) BOOL fileSizeUnknown;
@property (nonatomic, copy, readwrite) NSError *downloadError;
@property (nonatomic, strong) NSLock *lock;

@property (nonatomic, weak, readwrite) NSURLSessionDownloadTask *downloadTask;

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

- (instancetype)initWithSourceURLString:(NSString *)sourceURLString {
    self = [super init];
    if (self) {
        _sourceURLString = sourceURLString;
        _localURLString = nil;
        _downloadStatus = FYFontFileDownloadStateToBeDownloaded;
        _registered = NO;
        _lock = [[NSLock alloc] init];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)decoder {
    self = [super init];
    if (!self) {
        return nil;
    }
    _sourceURLString = [decoder decodeObjectForKey:@"_sourceURLString"];
    _localURLString = [decoder decodeObjectForKey:@"_localURLString"];
    _downloadStatus = [decoder decodeIntegerForKey:@"_downloadStatus"];
    _fileSize = [decoder decodeInt64ForKey:@"_fileSize"];
    _downloadProgress = [decoder decodeDoubleForKey:@"_downloadProgress"];
    _registered = NO;
    _lock = [[NSLock alloc] init];
    if (_downloadStatus == FYFontFileDownloadStateDownloaded) {
        _registered = [FYFontRegister registerFontInFile:self];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
    [encoder encodeObject:_sourceURLString forKey:@"_sourceURLString"];
    [encoder encodeObject:_localURLString forKey:@"_localURLString"];
    if ((_downloadStatus == FYFontFileDownloadStateSuspending) || (_downloadStatus == FYFontFileDownloadStateDownloading)) {
        _downloadStatus = FYFontFileDownloadStateToBeDownloaded;
    }
    [encoder encodeInteger:_downloadStatus forKey:@"_downloadStatus"];
    [encoder encodeInt64:_fileSize forKey:@"_fileSize"];
    [encoder encodeDouble:_downloadProgress forKey:@"_downloadProgress"];
    [encoder encodeBool:_registered forKey:@"_registered"];
    [encoder encodeObject:_fontModels forKey:@"_fontModels"];
}

#pragma mark - Public

- (void)clear {
    self.localURLString = nil;
    self.registered = NO;
    self.downloadProgress = 0.0;
    self.downloadStatus = FYFontFileDownloadStateToBeDownloaded;
}

- (void)resetWithDownloadTask:(NSURLSessionDownloadTask *)downloadTask {
    [self.lock lock];
    
    _downloadTask = downloadTask;
    
    _fileSize = _downloadTask.countOfBytesExpectedToReceive;
    _fileDownloadedSize = _downloadTask.countOfBytesReceived;
    _fileSizeUnknown = (_fileSize == NSURLSessionTransferSizeUnknown);
    _downloadError = _downloadTask.error;
    _downloadProgress = 0.0;
    
    switch (_downloadTask.state) {
        case NSURLSessionTaskStateRunning:
        case NSURLSessionTaskStateCanceling: {
            _downloadStatus = FYFontFileDownloadStateDownloading;
        } break;
            
        case NSURLSessionTaskStateSuspended: {
            _downloadStatus = FYFontFileDownloadStateSuspending;
        } break;
            
        case NSURLSessionTaskStateCompleted: {
            if (_downloadError) {
                _downloadStatus = FYFontFileDownloadStateToBeDownloaded;
            } else {
                _downloadStatus = FYFontFileDownloadStateDownloaded;
            }
        } break;
    }
    
    if (!_fileSizeUnknown) {
        double downloadProgress = (double)_fileDownloadedSize / _fileSize;
        if (downloadProgress > _downloadProgress) {
            _downloadProgress = downloadProgress;
        }
    }
    
    [self postSelf];
    
    [self.lock unlock];
}

#pragma mark - Private

- (void)postSelf {
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:FYFontFileDidChangeNotification
                                                            object:self
                                                          userInfo:@{FYFontFileDidChangeNotificationUserInfoKey:self}];
    });
}

#pragma mark - Accessor

- (void)setRegistered:(BOOL)registered {
    if (_registered != registered) {
        _registered = registered;
        [self postSelf];
    }
}

@end
