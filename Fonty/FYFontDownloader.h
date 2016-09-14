//
//  FYFontDownloader.h
//  Fonty
//
//  Created by 颜为晨 on 9/9/16.
//  Copyright © 2016 颜为晨. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FYFontDownloader : NSObject

+ (instancetype)sharedDownloader;

- (void)downloadFontWithURL:(NSURL *)URL;
- (void)suspendDownloadWithURL:(NSURL *)URL;

@end
