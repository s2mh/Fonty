//
//  FYDownloadDelegate.m
//  Fonty-Demo
//
//  Created by QQQ on 17/4/12.
//  Copyright © 2017年 s2mh. All rights reserved.
//

#import "FYDownloadDelegate.h"
#import "FYFontFile.h"
#import "FYFontCache.h"
#import "FYFontManager.h"

@interface FYDownloadDelegate ()

@property (nonatomic, weak) NSURLSessionDownloadTask *task;

@end

@implementation FYDownloadDelegate

- (instancetype)initWithTask:(NSURLSessionDownloadTask *)task
{
    self = [super init];
    if (self) {
        _task = task;
    }
    return self;
}

#pragma mark - NSURLSessionDownloadDelegate

- (void)URLSession:(NSURLSession *)session
      downloadTask:(NSURLSessionDownloadTask *)downloadTask
      didWriteData:(int64_t)bytesWritten
 totalBytesWritten:(int64_t)totalBytesWritten
totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite {
    [self.file resetWithDownloadTask:downloadTask];
    if (self.progress) {
        self.progress(self.file);
    };
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:FYFontFileDownloadingNotification
                                                            object:nil
                                                          userInfo:@{FYFontFileNotificationUserInfoKey:self.file}];
    });
}

- (void)URLSession:(NSURLSession *)session
      downloadTask:(NSURLSessionDownloadTask *)downloadTask
didFinishDownloadingToURL:(NSURL *)location {
    [FYFontCache cacheFile:self.file
                atLocation:location
         completionHandler:self.completionHandler];
}

- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionDownloadTask *)task
didCompleteWithError:(NSError *)error {
    [self.file resetWithDownloadTask:task];
    
    if (error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:FYFontFileDownloadingDidCompleteNotification
                                                                object:nil
                                                              userInfo:@{FYFontFileNotificationUserInfoKey:self.file}];
        });
        if (self.completionHandler) {
            self.completionHandler(error);
        }
    }
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(nullable NSString *)keyPath
                      ofObject:(nullable id)object
                        change:(nullable NSDictionary<NSKeyValueChangeKey, id> *)change
                       context:(nullable void *)context {
    if ([object isKindOfClass:[NSURLSessionDownloadTask class]]) {
        [self.file resetWithDownloadTask:self.task];
        if (self.progress) {
            self.progress(self.file);
        };
        if (self.task.state != NSURLSessionTaskStateCompleted) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [[NSNotificationCenter defaultCenter] postNotificationName:FYFontFileDownloadStateDidChangeNotification
                                                                    object:nil
                                                                  userInfo:@{FYFontFileNotificationUserInfoKey:self.file}];
            });
        }
    }
}

@end
