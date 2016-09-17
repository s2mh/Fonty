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
@property (nonatomic, strong) NSMutableDictionary<NSURL *, NSURLSessionDownloadTask *> *taskDictionary; // key:

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
    
    NSURLSessionDownloadTask *task = [self.taskDictionary objectForKey:URL];
    if (!task) {
        task = [self.session downloadTaskWithURL:URL];
        [self.taskDictionary setObject:task forKey:URL];
    }
    [task resume];
}

- (void)suspendDownloadWithURL:(NSURL *)URL {
    
    NSURLSessionDownloadTask *task = [self.taskDictionary objectForKey:URL];
    if (task) {
        [task suspend];
        FYFontModel *model = [FYFontModel modelWithURL:URL
                                                status:FYFontModelDownloadStatusSuspending
                                      downloadProgress:((double)task.countOfBytesReceived / task.countOfBytesExpectedToReceive)];
        NSDictionary *userInfo = @{FYNewFontDownloadNotificationKey:model};
        [[NSNotificationCenter defaultCenter] postNotificationName:FYNewFontDownloadNotification object:self userInfo:userInfo];
    }
}

#pragma mark - NSURLSessionDownloadDelegate

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask
                              didFinishDownloadingToURL:(NSURL *)location {
    
    NSString *path = [[FYFontCache sharedFontCache] cacheFileAtLocolURL:location fromWebURL:downloadTask.originalRequest.URL];
    [self.taskDictionary removeObjectForKey:downloadTask.originalRequest.URL];
    if (path) {
        dispatch_async(dispatch_get_main_queue(), ^{
            FYFontModel *model = [FYFontModel modelWithURL:downloadTask.originalRequest.URL
                                                    status:FYFontModelDownloadStatusDownloaded
                                          downloadProgress:1.0f];
            NSDictionary *userInfo = @{FYNewFontDownloadNotificationKey:model};
            [[NSNotificationCenter defaultCenter] postNotificationName:FYNewFontDownloadNotification object:self userInfo:userInfo];
        });
    }
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask
                                           didWriteData:(int64_t)bytesWritten
                                      totalBytesWritten:(int64_t)totalBytesWritten
                              totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite {
    
    if (totalBytesExpectedToWrite != NSURLSessionTransferSizeUnknown) {
        dispatch_async(dispatch_get_main_queue(), ^{
            FYFontModel *model = [FYFontModel modelWithURL:downloadTask.originalRequest.URL
                                                                  status:FYFontModelDownloadStatusDownloading
                                                        downloadProgress:(double)totalBytesWritten / totalBytesExpectedToWrite];
            NSDictionary *userInfo = @{FYNewFontDownloadNotificationKey:model};
            [[NSNotificationCenter defaultCenter] postNotificationName:FYNewFontDownloadNotification object:self userInfo:userInfo];
        });
    }
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

- (NSMutableDictionary *)taskDictionary {
    if (!_taskDictionary) {
        _taskDictionary = [NSMutableDictionary dictionary];
    }
    return _taskDictionary;
}

@end
