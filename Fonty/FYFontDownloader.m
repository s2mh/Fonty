//
//  FYFontDownloader.m
//  Fonty
//
//  Created by 颜为晨 on 9/9/16.
//  Copyright © 2016 颜为晨. All rights reserved.
//

#import "FYFontDownloader.h"
#import "FYFontCache.h"
#import "FYFontFile.h"
#import "FYDownloadDelegate.h"

@interface FYFontDownloader () <NSURLSessionDownloadDelegate>

@property (nonatomic, strong) NSURLSession *session;
@property (nonatomic, strong) NSLock *lock;
@property (nonatomic, strong) NSMutableDictionary<NSNumber *, FYDownloadDelegate *> *delegates;

@end

@implementation FYFontDownloader

- (void)downloadFontFile:(FYFontFile *)file
                progress:(void(^)(FYFontFile *file))progress
       completionHandler:(void(^)(NSError *))completionHandler {
    NSURLSessionDownloadTask *downloadTask = file.downloadTask;
    if (!downloadTask) {
        downloadTask = [self.session downloadTaskWithURL:[NSURL URLWithString:file.sourceURLString]];
        
        FYDownloadDelegate *delegate = [[FYDownloadDelegate alloc] initWithTask:downloadTask];
        delegate.progress = progress;
        delegate.completionHandler = completionHandler;
        delegate.file = file;

        [self setDelegate:delegate forTask:downloadTask];
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

#pragma mark - NSURLSessionDownloadDelegate

- (void)URLSession:(NSURLSession *)session
      downloadTask:(NSURLSessionDownloadTask *)downloadTask
      didWriteData:(int64_t)bytesWritten
 totalBytesWritten:(int64_t)totalBytesWritten
totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite {
    FYDownloadDelegate *delegate = [self delegateForTask:downloadTask];
    if (delegate) {
        [delegate URLSession:session
                downloadTask:downloadTask
                didWriteData:bytesWritten
           totalBytesWritten:totalBytesWritten
   totalBytesExpectedToWrite:totalBytesExpectedToWrite];
    }
}

- (void)URLSession:(NSURLSession *)session
      downloadTask:(NSURLSessionDownloadTask *)downloadTask
didFinishDownloadingToURL:(NSURL *)location {
    FYDownloadDelegate *delegate = [self delegateForTask:downloadTask];
    if (delegate) {
        [delegate URLSession:session
                downloadTask:downloadTask
   didFinishDownloadingToURL:location];
    }
}

- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionDownloadTask *)task
didCompleteWithError:(NSError *)error {
    FYDownloadDelegate *delegate = [self delegateForTask:task];
    if (delegate) {
        [delegate URLSession:session
                        task:task
        didCompleteWithError:error];
        [self removeDelegateForTask:task];
    }
}

#pragma mark - Private

- (FYDownloadDelegate *)delegateForTask:(NSURLSessionTask *)task {
    NSParameterAssert(task);
    
    FYDownloadDelegate *delegate = nil;
    [self.lock lock];
    delegate = self.delegates[@(task.taskIdentifier)];
    [self.lock unlock];
    
    return delegate;
}

- (void)setDelegate:(FYDownloadDelegate *)delegate
            forTask:(NSURLSessionTask *)task
{
    NSParameterAssert(task);
    NSParameterAssert(delegate);
    
    [self.lock lock];
    self.delegates[@(task.taskIdentifier)] = delegate;
    [task addObserver:delegate
           forKeyPath:@"state"
              options:NSKeyValueObservingOptionNew
              context:NULL];
    [self.lock unlock];
}

- (void)removeDelegateForTask:(NSURLSessionTask *)task {
    NSParameterAssert(task);
    
    [self.lock lock];
    [task removeObserver:self.delegates[@(task.taskIdentifier)] forKeyPath:@"state"];
    [self.delegates removeObjectForKey:@(task.taskIdentifier)];
    [self.lock unlock];
}

#pragma mark - Accessor

- (NSURLSession *)session {
    if (!_session) {
        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
        _session = [NSURLSession sessionWithConfiguration:configuration
                                                 delegate:self
                                            delegateQueue:nil];
    }
    return _session;
}

- (NSLock *)lock {
    if (!_lock) {
        _lock = [[NSLock alloc] init];
    }
    return _lock;
}

- (NSMutableDictionary<NSNumber *, FYDownloadDelegate *> *)delegates {
    if (!_delegates) {
        _delegates = [NSMutableDictionary dictionary];
    }
    return _delegates;
}

@end
