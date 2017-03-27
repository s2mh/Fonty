//
//  FYFontDownloader.h
//  Fonty
//
//  Created by 颜为晨 on 9/9/16.
//  Copyright © 2016 颜为晨. All rights reserved.
//

#import <Foundation/Foundation.h>

@class FYFontFile;

@interface FYFontDownloader : NSObject

+ (instancetype)sharedDownloader;

@property (nonatomic, copy) void(^trackDownloadBlock)(FYFontFile *file);
@property (nonatomic, assign) NSTimeInterval timeoutInterval;

- (void)downloadFontFile:(FYFontFile *)file;
- (void)cancelDownloadingFile:(FYFontFile *)file;
- (void)suspendDownloadFile:(FYFontFile *)file;

@end
