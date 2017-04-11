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
    [FYFontManager setFileURLStrings:@[@"https://github.com/s2mh/FontFile/raw/master/Chinese/Simplified%20Chinese/ttc/Xingkai.ttc",
                                       @"https://github.com/s2mh/FontFile/raw/master/Common/Bold/LiHeiPro.ttf",
                                       @"https://github.com/s2mh/FontFile/raw/master/English/Bold/Luminari.ttf",
                                       @"https://github.com/s2mh/FontFile/raw/master/Common/Regular/YuppySC-Regular.otf",
                                       @"https://github.com/s2mh/FontFile/raw/master/Common/Regular/YuppyTC-Regular.otf"]];
    
    return YES;
}

@end
