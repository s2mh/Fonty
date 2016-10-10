//
//  FYFontDownloader.m
//  Fonty
//
//  Created by 颜为晨 on 9/9/16.
//  Copyright © 2016 颜为晨. All rights reserved.
//

#import "FYFontDownloader.h"
#import "FYFontCache.h"
#import "FYFontModel.h"
#import "FYConst.h"

@interface FYFontDownloader () <NSURLSessionDownloadDelegate>

@property (nonatomic, strong) NSURLSession *session;
@property (nonatomic, strong) NSMutableDictionary<NSURL *, NSURLSessionDownloadTask *> *taskDictionary;

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

- (void)downloadFontWithURL:(NSURL *)URL {
    NSURLSessionDownloadTask *downloadTask = [self.taskDictionary objectForKey:URL];
    if (!downloadTask) {
        downloadTask = [self.session downloadTaskWithURL:URL];
        [downloadTask addObserver:self forKeyPath:@"state" options:NSKeyValueObservingOptionNew context:NULL];
        [self.taskDictionary setObject:downloadTask forKey:URL];
    }
    if (downloadTask && (downloadTask.state == NSURLSessionTaskStateSuspended)) {
        [downloadTask resume];
    }
}

- (void)cancelDownloadingFontWithURL:(NSURL *)URL {
    NSURLSessionDownloadTask *downloadTask = [self.taskDictionary objectForKey:URL];
    if (downloadTask) {
//        [self freeTask:downloadTask];
        [downloadTask cancelByProducingResumeData:^(NSData * _Nullable resumeData) {}];
    }
}

- (void)suspendDownloadWithURL:(NSURL *)URL {
    NSURLSessionDownloadTask *downloadTask = [self.taskDictionary objectForKey:URL];
    if (downloadTask) {
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
    [[FYFontCache sharedFontCache] cacheFileAtLocolURL:location fromWebURL:downloadTask.originalRequest.URL];
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
    NSDictionary *userInfo = @{FYNewFontDownloadNotificationKey:[FYFontModel modelWithSessionDownloadTask:task]};
    if (task.state == NSURLSessionTaskStateCompleted) {
        [self freeTask:task];
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:FYNewFontDownloadNotification object:self userInfo:userInfo];
    });
}

- (void)freeTask:(NSURLSessionDownloadTask *)task {
    [self.taskDictionary removeObjectForKey:task.originalRequest.URL];
    [task removeObserver:self forKeyPath:@"state"];
}

#pragma mark - accessor

- (NSURLSession *)session {
    if (!_session) {
        _session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]
                                                 delegate:self
                                            delegateQueue:nil];
    }
    return _session;
}

- (NSMutableDictionary<NSURL *, NSURLSessionDownloadTask *> *)taskDictionary {
    if (!_taskDictionary) {
        _taskDictionary = [NSMutableDictionary dictionary];
    }
    return _taskDictionary;
}

@end
