		//
//  FYFontRegister.m
//  Fonty
//
//  Created by 颜为晨 on 9/9/16.
//  Copyright © 2016 颜为晨. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreText/CoreText.h>

#import "FYFontRegister.h"
#import "FYFontManager.h"
#import "FYFontFile.h"

NSString * const FYFontRegisterErrorPostScriptName = @"FYFontRegisterErrorPostScriptName";

@implementation FYFontRegister

+ (BOOL)registerFontInFile:(FYFontFile *)file {
    CFStringRef fontPath = CFStringCreateWithCString(NULL, [file.localPath UTF8String], kCFStringEncodingUTF8);
    CFURLRef fontURL = CFURLCreateWithFileSystemPath(NULL, fontPath, kCFURLPOSIXPathStyle, 0);
    CFErrorRef error = NULL;
    CTFontManagerRegisterFontsForURL(fontURL, kCTFontManagerScopeNone, &error);
    
    if (error) {
        CFRelease(fontURL);
        CFRelease(fontPath);
        CFRelease(error);
        return NO;
    }
    CFArrayRef fontArray = CTFontManagerCreateFontDescriptorsFromURL(fontURL);
    NSMutableArray *fontModels = [NSMutableArray array];
    if (fontArray) {
        CGFloat size = 0.0;
        for (CFIndex i = 0 ; i < CFArrayGetCount(fontArray); i++) {
            CTFontDescriptorRef descriptor = CFArrayGetValueAtIndex(fontArray, i);
            CTFontRef fontRef = CTFontCreateWithFontDescriptor(descriptor, size, NULL);
            CFStringRef fontName = CTFontCopyName(fontRef, kCTFontPostScriptNameKey);
            UIFont *font = CFBridgingRelease(CTFontCreateWithNameAndOptions(fontName, 0.0, NULL, kCTFontOptionsDefault));
            if (font) {
                FYFontModel *model = [[FYFontModel alloc] init];
                model.postScriptName = CFBridgingRelease(fontName);
                model.font = font;
                model.fontFile = file;
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
    CFRelease(fontPath);
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:FYFontFileRegisteringDidCompleteNotification
                                                            object:nil
                                                          userInfo:@{FYFontFileNotificationUserInfoKey:file}];
    });
    
    return YES;
}

+ (BOOL)unregisterFontInFile:(FYFontFile *)file {
    BOOL success = YES;
    if (file.localPath) {
        CFStringRef fontPath = CFStringCreateWithCString(NULL, [file.localPath UTF8String], kCFStringEncodingUTF8);
        CFURLRef fontURL = CFURLCreateWithFileSystemPath(NULL, fontPath, kCFURLPOSIXPathStyle, 0);
        if (fontURL) {
            success = CTFontManagerUnregisterFontsForURL(fontURL, kCTFontManagerScopeNone, NULL);
        }
        CFRelease(fontURL);
        CFRelease(fontPath);
    }
    return success;
}


@end
