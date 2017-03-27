//
//  FYFontRegister.m
//  Fonty
//
//  Created by 颜为晨 on 9/9/16.
//  Copyright © 2016 颜为晨. All rights reserved.
//

#import <CoreText/CoreText.h>
#import <UIKit/UIKit.h>
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

- (NSString *)registerFontWithPath1:(NSString *)path {
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

- (NSArray<FYFontModel *> *)registerFontWithPath:(NSString *)path {
    CFStringRef fontPath = CFStringCreateWithCString(NULL, [path UTF8String], kCFStringEncodingUTF8);
    CFURLRef fontURL = CFURLCreateWithFileSystemPath(NULL, fontPath, kCFURLPOSIXPathStyle, 0);
    CTFontManagerRegisterFontsForURL(fontURL, kCTFontManagerScopeNone, NULL);
    CFArrayRef fontArray = CTFontManagerCreateFontDescriptorsFromURL(fontURL);
    NSMutableArray *customFontArray = [NSMutableArray array];
    CGFloat size = 0.0;
    for (CFIndex i = 0 ; i < CFArrayGetCount(fontArray); i++) {
        CTFontDescriptorRef descriptor = CFArrayGetValueAtIndex(fontArray, i);
        CTFontRef fontRef = CTFontCreateWithFontDescriptor(descriptor, size, NULL);
        NSString *fontName = CFBridgingRelease(CTFontCopyName(fontRef, kCTFontPostScriptNameKey));
        UIFont *font = [UIFont fontWithName:fontName size:size];
        
        FYFontModel *model = [[FYFontModel alloc] init];
        model.postScriptName = fontName;
        model.font = font;
        [customFontArray addObject:fontName];
        CFRelease(fontRef);
    }
    CFRelease(fontArray);
    CFRelease(fontURL);
    CFRelease(fontPath);
    
    return [customFontArray copy];
}


- (BOOL)registerFontInFile:(FYFontFile *)file {
    CFStringRef fontPath = CFStringCreateWithCString(NULL, [file.fileLocalURL UTF8String], kCFStringEncodingUTF8);
    CFURLRef fontURL = CFURLCreateWithFileSystemPath(NULL, fontPath, kCFURLPOSIXPathStyle, 0);
    CTFontManagerRegisterFontsForURL(fontURL, kCTFontManagerScopeNone, NULL);
    CFArrayRef fontArray = CTFontManagerCreateFontDescriptorsFromURL(fontURL);
    NSMutableArray *fontModels = [NSMutableArray array];
    CGFloat size = 0.0;
    for (CFIndex i = 0 ; i < CFArrayGetCount(fontArray); i++) {
        CTFontDescriptorRef descriptor = CFArrayGetValueAtIndex(fontArray, i);
        CTFontRef fontRef = CTFontCreateWithFontDescriptor(descriptor, size, NULL);
        NSString *fontName = CFBridgingRelease(CTFontCopyName(fontRef, kCTFontPostScriptNameKey));
        UIFont *font = [UIFont fontWithName:fontName size:size];
        
        FYFontModel *model = [[FYFontModel alloc] init];
        model.postScriptName = fontName;
        model.font = font;
        [fontModels addObject:fontName];
        CFRelease(fontRef);
    }
    file.fontModels = fontModels;
    
    CFRelease(fontArray);
    CFRelease(fontURL);
    CFRelease(fontPath);
    
    return (fontModels.count > 0);
}

- (void)unregisterFontWithPath1:(NSString *)path {
    NSURL *fontURL = [NSURL fileURLWithPath:path];
    CGDataProviderRef fontDataProvider = CGDataProviderCreateWithURL((__bridge CFURLRef)fontURL);
    CGFontRef fontRef = CGFontCreateWithDataProvider(fontDataProvider);
    if (fontRef) {
        CTFontManagerUnregisterGraphicsFont(fontRef, NULL);
        CGFontRelease(fontRef);
    }
    CGDataProviderRelease(fontDataProvider);
}

- (void)unregisterFontWithPath:(NSString *)path {
    CFStringRef fontPath = CFStringCreateWithCString(NULL, [path UTF8String], kCFStringEncodingUTF8);
    CFURLRef fontURL = CFURLCreateWithFileSystemPath(NULL, fontPath, kCFURLPOSIXPathStyle, 0);
    if (fontURL) {
        CTFontManagerUnregisterFontsForURL(fontURL, kCTFontManagerScopeNone, NULL);
    }
    CFRelease(fontURL);
    CFRelease(fontPath);
}


@end
