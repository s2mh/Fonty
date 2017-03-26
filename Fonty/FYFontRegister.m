//
//  FYFontRegister.m
//  Fonty
//
//  Created by 颜为晨 on 9/9/16.
//  Copyright © 2016 颜为晨. All rights reserved.
//

#import <CoreText/CoreText.h>
#import "FYFontRegister.h"

NSString * const FYFontRegisterErrorPostScriptName = @"FYFontRegisterErrorPostScriptName";

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
    if (fontRef && CTFontManagerRegisterGraphicsFont(fontRef, NULL)) {
        postScriptName = CFBridgingRelease(CGFontCopyPostScriptName(fontRef));
        CGFontRelease(fontRef);
    }
    CGDataProviderRelease(fontDataProvider);
    
    if (!postScriptName) {
        postScriptName = FYFontRegisterErrorPostScriptName;
    }
    
    return postScriptName;
}

- (NSArray *)customFontArrayWithPath:(NSString *)path size:(CGFloat)size
{
    CFStringRef fontPath = CFStringCreateWithCString(NULL, [path UTF8String], kCFStringEncodingUTF8);
    CFURLRef fontUrl = CFURLCreateWithFileSystemPath(NULL, fontPath, kCFURLPOSIXPathStyle, 0);
    CFArrayRef fontArray = CTFontManagerCreateFontDescriptorsFromURL(fontUrl);
    CTFontManagerRegisterFontsForURL(fontUrl, kCTFontManagerScopeNone, NULL);
    NSMutableArray *customFontArray = [NSMutableArray array];
    for (CFIndex i = 0 ; i < CFArrayGetCount(fontArray); i++){
        CTFontDescriptorRef descriptor = CFArrayGetValueAtIndex(fontArray, i);
        CTFontRef fontRef = CTFontCreateWithFontDescriptor(descriptor, size, NULL);
        NSString *fontName = CFBridgingRelease(CTFontCopyName(fontRef, kCTFontPostScriptNameKey));
        [customFontArray addObject:fontName];
    }
    
    
    return customFontArray;
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
