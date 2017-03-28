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

//- (NSString *)registerFontWithPath:(NSString *)path {
//    NSString *postScriptName = nil;
//    NSURL *fontURL = [NSURL fileURLWithPath:path];
//    CGDataProviderRef fontDataProvider = CGDataProviderCreateWithURL((__bridge CFURLRef)fontURL);
//    CGFontRef fontRef = CGFontCreateWithDataProvider(fontDataProvider);
//    if (fontRef && CTFontManagerRegisterGraphicsFont(fontRef, NULL)) {
//        postScriptName = CFBridgingRelease(CGFontCopyPostScriptName(fontRef));
//        CGFontRelease(fontRef);
//    }
//    CGDataProviderRelease(fontDataProvider);
//    
//    if (!postScriptName) {
//        postScriptName = FYFontRegisterErrorPostScriptName;
//    }
//    
//    return postScriptName;
//}

- (void)registerFontInFile:(FYFontFile *)file completeHandler:(void(^)(BOOL success))handler {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
//        CFStringRef fontPath = CFStringCreateWithCString(NULL, [file.localURL.absoluteString UTF8String], kCFStringEncodingUTF8);
//        CFURLRef fontURL = CFURLCreateWithFileSystemPath(NULL, fontPath, kCFURLPOSIXPathStyle, 0);
        CFErrorRef error = NULL;
        
        CFURLRef fontURL = (__bridge CFURLRef)file.localURL;
        
        bool can = CTFontManagerRegisterFontsForURL(fontURL, kCTFontManagerScopeNone, &error);
        if (error) {
            NSLog(@"xkxkxkxk %@", error);
            // Registration will fail, if the font HAS been registered!
        }
        NSLog(@"cacac %d", can);
        CFArrayRef fontArray = CTFontManagerCreateFontDescriptorsFromURL(fontURL);
        NSMutableArray *fontModels = [NSMutableArray array];
        NSLog(@"CTFontManagerRegisterFontsForURL %@", fontArray);
        if (fontArray) {
            CGFloat size = 0.0;
            for (CFIndex i = 0 ; i < CFArrayGetCount(fontArray); i++) {
                CTFontDescriptorRef descriptor = CFArrayGetValueAtIndex(fontArray, i);
                CTFontRef fontRef = CTFontCreateWithFontDescriptor(descriptor, size, NULL);
                CFStringRef fontName = CTFontCopyName(fontRef, kCTFontPostScriptNameKey);
                UIFont *font = CFBridgingRelease(CTFontCreateWithNameAndOptions(fontName, 0.0, NULL, kCTFontOptionsDefault));
                if (font) {
                    NSLog(@"xxxx  fontName %@ postscriptName %@", fontName, font.fontDescriptor.postscriptName);
                    FYFontModel *model = [[FYFontModel alloc] init];
                    model.postScriptName = CFBridgingRelease(fontName);
                    model.font = font;
                    [fontModels addObject:model];
                }
                CFRelease(fontRef);
            }
            file.fontModels = fontModels;
            if (fontModels.count > 0) {
                file.registered = YES;
            }
            
            CFRelease(fontArray);
        }
        
        CFRelease(fontURL);
//        CFRelease(fontPath);
        
        if (handler) {
            dispatch_async(dispatch_get_main_queue(), ^{
                handler(fontModels.count > 0);
            });
        }
    });
}

- (void)unregisterFontInFile:(FYFontFile *)file completeHandler:(void(^)(BOOL success))handler {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        CFStringRef fontPath = CFStringCreateWithCString(NULL, [file.localURL.absoluteString UTF8String], kCFStringEncodingUTF8);
        CFURLRef fontURL = CFURLCreateWithFileSystemPath(NULL, fontPath, kCFURLPOSIXPathStyle, 0);
        BOOL success = NO;
        if (fontURL) {
            success = CTFontManagerUnregisterFontsForURL(fontURL, kCTFontManagerScopeNone, NULL);
        }
        CFRelease(fontURL);
        CFRelease(fontPath);
        if (success) {
            file.registered = NO;
        }
        if (handler) {
            dispatch_async(dispatch_get_main_queue(), ^{
                handler(success);
            });
        }
    });
}


@end
