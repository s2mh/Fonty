//
//  FYFontRegister.m
//  Fonty
//
//  Created by 颜为晨 on 9/9/16.
//  Copyright © 2016 颜为晨. All rights reserved.
//

#import <CoreText/CTFontManager.h>
#import "FYFontRegister.h"

@implementation FYFontRegister

+ (instancetype)sharedRegister {
    static id instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [self new];
    });
    return instance;
}

- (NSString *)registerFontWithPath:(NSString *)path {
    NSString *postScriptName = nil;
    NSURL *fontURL = [NSURL fileURLWithPath:path];
    CGDataProviderRef fontDataProvider = CGDataProviderCreateWithURL((__bridge CFURLRef)fontURL);
    CGFontRef fontRef = CGFontCreateWithDataProvider(fontDataProvider);
    if (fontRef) {
        CTFontManagerRegisterGraphicsFont(fontRef, NULL);
        postScriptName = CFBridgingRelease(CGFontCopyPostScriptName(fontRef));
        CGFontRelease(fontRef);
    }
    CGDataProviderRelease(fontDataProvider);
    return postScriptName;
}

- (void)unregisterFontWithPath:(NSString *)path {
    NSURL *fontURL = [NSURL fileURLWithPath:path];
    CGDataProviderRef fontDataProvider = CGDataProviderCreateWithURL((__bridge CFURLRef)fontURL);
    CGFontRef fontRef = CGFontCreateWithDataProvider(fontDataProvider);
    if (fontRef) {
        CTFontManagerUnregisterGraphicsFont(fontRef, NULL);
        CGFontRelease(fontRef);
    }
    CGDataProviderRelease(fontDataProvider);
}

@end
