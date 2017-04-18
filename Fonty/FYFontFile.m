//
//  FYFontFile.m
//  Fonty-Demo
//
//  Created by QQQ on 17/3/27.
//  Copyright © 2017年 s2mh. All rights reserved.
//

#import <objc/runtime.h>

#import "FYFontFile.h"
#import "FYFontCache.h"
#import "FYFontRegister.h"
#import "FYFontDownloader.h"
#import "FYFontManager.h"

@interface FYFontFile ()

@property (nonatomic, copy, readwrite) NSString *sourceURLString;
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

- (instancetype)initWithSourceURLString:(NSString *)sourceURLString {
    self = [super init];
    if (self) {
        _sourceURLString = sourceURLString;
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
    _fileName = [decoder decodeObjectForKey:@"_fileName"];
    _localPath = [[FYFontCache diskCacheDirectoryPath] stringByAppendingPathComponent:_fileName];
    _downloadStatus = [decoder decodeIntegerForKey:@"_downloadStatus"];
    _fileSize = [decoder decodeInt64ForKey:@"_fileSize"];
    _downloadProgress = [decoder decodeDoubleForKey:@"_downloadProgress"];
    _registered = NO;
    _lock = [[NSLock alloc] init];
    if (_downloadStatus == FYFontFileDownloadStateDownloaded) {
        _registered = [FYFontRegister registerFontInFile:self];
        if (!_registered) {
            [self clear];
        }
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
    [encoder encodeObject:_sourceURLString forKey:@"_sourceURLString"];
    [encoder encodeObject:_fileName forKey:@"_fileName"];
    if ((_downloadStatus == FYFontFileDownloadStateSuspended) || (_downloadStatus == FYFontFileDownloadStateDownloading)) {
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
    [self.lock lock];
    self.localPath = nil;
    self.fileName = nil;
    self.registered = NO;
    self.downloadProgress = 0.0;
    self.downloadStatus = FYFontFileDownloadStateToBeDownloaded;
    self.fontModels = nil;
    [self.lock unlock];
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
        case NSURLSessionTaskStateRunning: {
            _downloadStatus = FYFontFileDownloadStateDownloading;
        } break;
            
        case NSURLSessionTaskStateSuspended: {
            _downloadStatus = FYFontFileDownloadStateSuspended;
        } break;
            
        case NSURLSessionTaskStateCanceling: {
            _downloadStatus = FYFontFileDownloadStateToBeDownloaded;
            _fileDownloadedSize = 0.0;
        } break;
            
        case NSURLSessionTaskStateCompleted: {
            if (_downloadError) {
                _downloadStatus = FYFontFileDownloadStateToBeDownloaded;
                _fileDownloadedSize = 0.0;
            } else {
                _downloadStatus = FYFontFileDownloadStateDownloaded;
            }
        } break;
    }
    
    if (!_fileSizeUnknown) {
        double downloadProgress = (double)_fileDownloadedSize / _fileSize;
        if ((downloadProgress > _downloadProgress) || (_downloadStatus == FYFontFileDownloadStateToBeDownloaded)) {
            _downloadProgress = downloadProgress;
        }
    }
    [self.lock unlock];
}

@end

@implementation FYFontModel

- (instancetype)initWithCoder:(NSCoder *)decoder {
    self = [super init];
    if (!self) {
        return nil;
    }
    _postScriptName = [decoder decodeObjectForKey:@"_postScriptName"];
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
    [encoder encodeObject:_postScriptName forKey:@"_postScriptName"];
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"%@", self.postScriptName];
}

@end
