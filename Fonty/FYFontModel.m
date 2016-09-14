//
//  FYFontModel.m
//  Fonty
//
//  Created by 颜为晨 on 9/8/16.
//  Copyright © 2016 颜为晨. All rights reserved.
//

#import "FYFontModel.h"

@implementation FYFontModel

- (NSString *)description
{
    if (self.URL) {
        return self.URL.absoluteString;
    } else {
        return @"system default font";
    }
}

+ (instancetype)modelWithURL:(NSURL *)URL
                      status:(FYFontModelDownloadStatus)status
            downloadProgress:(double)downloadProgress {
    FYFontModel *model = [[FYFontModel alloc] init];
    model.URL = URL;
    model.status = status;
    model.downloadProgress = downloadProgress;
    model.postScriptName = @"";
    return model;
}

@end
