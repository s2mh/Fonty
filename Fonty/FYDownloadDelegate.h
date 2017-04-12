//
//  FYDownloadDelegate.h
//  Fonty-Demo
//
//  Created by QQQ on 17/4/12.
//  Copyright © 2017年 s2mh. All rights reserved.
//

#import <Foundation/Foundation.h>

@class FYFontFile;

@interface FYDownloadDelegate : NSObject <NSURLSessionDownloadDelegate>

- (instancetype)initWithTask:(NSURLSessionDownloadTask *)task;

@property (nonatomic, weak) FYFontFile *file;
@property (nonatomic, copy) void(^progress)(FYFontFile *file);
@property (nonatomic, copy) void(^completionHandler)(NSError *error);

@end
