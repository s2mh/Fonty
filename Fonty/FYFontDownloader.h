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

- (void)downloadFontFile:(FYFontFile *)file progress:(void(^)(FYFontFile *file))progress completionHandler:(void(^)(NSError *error))completionHandler;
- (void)cancelDownloadingFile:(FYFontFile *)file;
- (void)suspendDownloadFile:(FYFontFile *)file;

@end
