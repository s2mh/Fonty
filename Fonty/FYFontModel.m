//
//  FYFontModel.m
//  Fonty
//
//  Created by 颜为晨 on 9/8/16.
//  Copyright © 2016 颜为晨. All rights reserved.
//

#import <objc/runtime.h>
#import <objc/message.h>
#import "FYFontModel.h"

@implementation FYFontModel

- (instancetype)init
{
    self = [super init];
    if (self) {
        _downloadURL = nil;
        _status = FYFontModelDownloadStatusToBeDownloaded;
        _type = FYFontTypeFont;
        _downloadProgress = 0.0f;
        _postScriptName = @"";
        _fileSize = 0.0f;
        _fileSizeUnknown = NO;
        _downloadError = nil;
    }
    return self;
}

- (NSString *)description
{
    if (self.downloadURL) {
        return self.downloadURL.absoluteString;
    } else {
        switch (self.type) {
            case FYFontTypeFont:        return @"Default Font";
            case FYFontTypeBoldFont:    return @"Default Bold Font";
            case FYFontTypeItalicFont:  return @"Default Italic Font";
        }
    }
}

@end
