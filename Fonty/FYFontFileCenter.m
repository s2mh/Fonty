//
//  FYFontFileCenter.m
//  Fonty-Demo
//
//  Created by QQQ on 17/3/27.
//  Copyright © 2017年 s2mh. All rights reserved.
//

#import "FYFontFileCenter.h"

@interface FYFontFileCenter ()

@property (copy) NSArray<NSString *> *URLStrings;
@property (copy) NSArray<FYFontFile *> *fontFiles;

@end

@implementation FYFontFileCenter

+ (instancetype)sharedCenter {
    static id center;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        center = [self new];
    });
    return center;
}

#pragma mark - Accessor

+ (NSArray<NSString *> *)URLStrings {
    return [[FYFontFileCenter sharedCenter] URLStrings];
}

+ (void)setURLStrings:(NSArray<NSString *> *)URLStrings {
    FYFontFileCenter *sharedCenter = [FYFontFileCenter sharedCenter];
    if (URLStrings != sharedCenter.URLStrings) {
        dispatch_semaphore_t semaphore = dispatch_semaphore_create(1);
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
        
        NSMutableArray<FYFontFile *> *fontFiles = [NSMutableArray arrayWithCapacity:URLStrings.count];
        [URLStrings enumerateObjectsUsingBlock:^(NSString * _Nonnull URLString, NSUInteger idx, BOOL * _Nonnull stop) {
            FYFontFile *file = [[FYFontFile alloc] initWithURLString:URLString];
            [fontFiles addObject:file];
        }];
        sharedCenter.fontFiles = [fontFiles copy];
        sharedCenter.URLStrings = [URLStrings copy];
        dispatch_semaphore_signal(semaphore);
    }
}

+ (NSArray<FYFontFile *> *)fontFiles {
    return [[FYFontFileCenter sharedCenter] fontFiles];
}

@end
