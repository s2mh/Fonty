//
//  AppDelegate.m
//  Fonty-Demo
//
//  Created by 颜为晨 on 9/12/16.
//  Copyright © 2016 s2mh. All rights reserved.
//

#import "AppDelegate.h"
#import "FYFontManager.h"

@interface AppDelegate ()

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {    
    [FYFontManager setFontURLStringArray:@[@"https://github.com/s2mh/Fonty/raw/master/SourceFontFiles/SizeKnownFont.ttf",
                                           @"http://115.28.28.235:8088/SizeUnknownFont.ttf",
                                           @"https://github.com/s2mh/FontFile/raw/master/English/ttc/SnellRoundhand.ttc"]];
    [FYFontManager setBoldFontURLStringArray:@[@"https://github.com/s2mh/Fonty/raw/master/SourceFontFiles/SizeKnownBoldFont.ttf",
                                               @"http://115.28.28.235:8088/SizeUnknownBoldFont.otf"]];
    [FYFontManager setItalicFontURLStringArray:@[@"https://github.com/s2mh/Fonty/raw/master/SourceFontFiles/SizeKnownItalicFont.ttf"]];
    return YES;
}

@end
