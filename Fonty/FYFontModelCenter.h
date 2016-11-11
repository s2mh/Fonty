//
//  FYFontModelCenter.h
//  Fonty-Demo
//
//  Created by 颜为晨 on 11/4/16.
//  Copyright © 2016 s2mh. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FYFontModel.h"

@interface FYFontModelCenter : NSObject

+ (void)setFontURLStringArray:(NSArray<NSString *> *)URLStringArray;
+ (void)setBoldFontURLStringArray:(NSArray<NSString *> *)URLStringArray;
+ (void)setItalicFontURLStringArray:(NSArray<NSString *> *)URLStringArray;

+ (NSMutableArray<FYFontModel *> *)fontModelArray;
+ (NSMutableArray<FYFontModel *> *)boldFontModelArray;
+ (NSMutableArray<FYFontModel *> *)italicFontModelArray;

+ (FYFontModel *)fontModelWithURLString:(NSString *)URLString;
+ (NSUInteger)indexOfModel:(FYFontModel *)model;

@end
