//
//  AppDelegate.m
//  Fonty-Demo
//
//  Created by 颜为晨 on 9/12/16.
//  Copyright © 2016 s2mh. All rights reserved.
//

#import "AppDelegate.h"
#import "FYHeader.h"

@interface AppDelegate ()

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    [FYFontManager setFontURLStringArray:@[@"http://115.28.28.235:8088/SizeKnownFont.ttf",
                                           @"http://115.28.28.235:8088/SizeUnknownFont.ttf"]];
    [FYFontManager setBoldFontURLStringArray:@[@"http://115.28.28.235:8088/SizeKnownBoldFont.ttf",
                                               @"http://115.28.28.235:8088/SizeUnknownBoldFont.otf"]];
    [FYFontManager setItalicFontURLStringArray:@[]];
    return YES;
}

@end
