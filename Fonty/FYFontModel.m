//
//  FYFontModel.m
//  Fonty
//
//  Created by 颜为晨 on 9/8/16.
//  Copyright © 2016 颜为晨. All rights reserved.
//

#import "FYFontModel.h"

@implementation FYFontModel

+ (instancetype)modelWithURL:(NSURL *)URL
                      status:(FYFontModelDownloadStatus)status
            downloadProgress:(float)downloadProgress {
    FYFontModel *model = [[FYFontModel alloc] init];
    model.URL = URL;
    model.status = status;
    model.downloadProgress = downloadProgress;
    model.postScriptName = @"";
    return model;
}

@end
