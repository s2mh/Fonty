//
//  FYFontDownloader.m
//  Fonty
//
//  Created by 颜为晨 on 9/9/16.
//  Copyright © 2016 颜为晨. All rights reserved.
//

#import "FYFontDownloader.h"
#import "FYFontCache.h"
#import "FYConst.h"
#import "FYFontFile.h"

@interface FYFontDownloader () <NSURLSessionDownloadDelegate>

@property (nonatomic, strong) NSURLSession *session;
@property (nonatomic, strong) NSMutableDictionary<NSURLSessionDownloadTask *, FYFontFile *> *fileDictionary;

@end

@implementation FYFontDownloader

+ (instancetype)sharedDownloader {
    static id instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [self new];
    });
    return instance;
}


- (void)downloadFontFile:(FYFontFile *)file {
    NSURLSessionDownloadTask *downloadTask = file.downloadTask;
    if (!downloadTask) {
        downloadTask = [self.session downloadTaskWithURL:file.fileDownloadURL];
        [downloadTask addObserver:self forKeyPath:@"state" options:NSKeyValueObservingOptionNew context:NULL];
        file.downloadTask = downloadTask;
        [self.fileDictionary setObject:file
                                forKey:downloadTask];
    }
    if (downloadTask && (downloadTask.state == NSURLSessionTaskStateSuspended)) {
        [downloadTask resume];
    }
}


- (void)cancelDownloadingFile:(FYFontFile *)file {
    NSURLSessionDownloadTask *downloadTask = file.downloadTask;
    if (downloadTask && (downloadTask.state == NSURLSessionTaskStateRunning || downloadTask.state == NSURLSessionTaskStateSuspended)) {
        [downloadTask cancelByProducingResumeData:^(NSData * _Nullable resumeData) {}];
    }
}

- (void)suspendDownloadFile:(FYFontFile *)file {
    NSURLSessionDownloadTask *downloadTask = file.downloadTask;
    if (downloadTask && (downloadTask.state == NSURLSessionTaskStateRunning)) {
        [downloadTask suspend];
    }
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(nullable NSString *)keyPath ofObject:(nullable id)object change:(nullable NSDictionary<NSKeyValueChangeKey, id> *)change context:(nullable void *)context {
    if ([object isKindOfClass:[NSURLSessionDownloadTask class]]) {
        [self trackDownloadTask:(NSURLSessionDownloadTask *)object];
    }
}

#pragma mark - NSURLSessionDownloadDelegate

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask
                              didFinishDownloadingToURL:(NSURL *)location {
    [self trackDownloadTask:downloadTask];
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask
                                           didWriteData:(int64_t)bytesWritten
                                      totalBytesWritten:(int64_t)totalBytesWritten
                              totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite {
    [self trackDownloadTask:downloadTask];
}

#pragma mark - Private

- (void)trackDownloadTask:(NSURLSessionDownloadTask *)task {
    if (self.trackDownloadBlock) {
        FYFontFile *file = [self.fileDictionary objectForKey:task];
        self.trackDownloadBlock(file);
    }
    if (task.state == NSURLSessionTaskStateCompleted) {
        [self freeTask:task];
    }
}

- (void)freeTask:(NSURLSessionDownloadTask *)task {
    [self.fileDictionary removeObjectForKey:task];
    [task removeObserver:self forKeyPath:@"state"];
}

#pragma mark - accessor

- (NSURLSession *)session {
    if (!_session) {
        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
        configuration.timeoutIntervalForRequest = _timeoutInterval;
        _session = [NSURLSession sessionWithConfiguration:configuration
                                                 delegate:self
                                            delegateQueue:nil];
    }
    return _session;
}

- (NSMutableDictionary<NSURLSessionDownloadTask *, FYFontFile *> *)fileDictionary {
    if (!_fileDictionary) {
        _fileDictionary = [NSMutableDictionary dictionary];
    }
    return _fileDictionary;
}

@end
