//
//  FYFontModelCenter.m
//  Fonty-Demo
//
//  Created by 颜为晨 on 11/4/16.
//  Copyright © 2016 s2mh. All rights reserved.
//

#import "FYFontModelCenter.h"
#import "FYFontCache.h"

@interface FYFontModelCenter ()

@property (nonatomic, strong) NSArray<NSString *> *fontURLStringArray;
@property (nonatomic, strong) NSArray<NSString *> *boldFontURLStringArray;
@property (nonatomic, strong) NSArray<NSString *> *italicFontURLStringArray;

@property (nonatomic, strong) NSMutableArray<FYFontModel *> *fontModelArray;
@property (nonatomic, strong) NSMutableArray<FYFontModel *> *boldFontModelArray;
@property (nonatomic, strong) NSMutableArray<FYFontModel *> *italicFontModelArray;

@property (nonatomic, strong) NSArray<NSMutableArray *> *fontModelContainer;

@end

@implementation FYFontModelCenter

+ (instancetype)defaultCenter {
    static id center;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        center = [FYFontModelCenter new];
    });
    return center;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _fontModelArray       = [NSMutableArray array];
        _boldFontModelArray   = [NSMutableArray array];
        _italicFontModelArray = [NSMutableArray array];
        
        _fontModelContainer = @[_fontModelArray, _boldFontModelArray, _italicFontModelArray];
    }
    return self;
}

#pragma mark - Private

+ (NSArray<FYFontModel *> *)assembleModelArrayWithURLStringArray:(NSArray<NSString *> *)fontURLStringArray type:(FYFontType)type{
    NSMutableArray *fontModelArray = [NSMutableArray array];
    
    FYFontModel *systemDefaultFontModel = [[FYFontModel alloc] init];
    systemDefaultFontModel.type = type;
    systemDefaultFontModel.status = FYFontModelDownloadStatusDownloaded;
    systemDefaultFontModel.downloadProgress = 1.0f;
    systemDefaultFontModel.fileSizeUnknown = NO;
    [fontModelArray addObject:systemDefaultFontModel];
    
    [fontURLStringArray enumerateObjectsUsingBlock:^(NSString * _Nonnull URLString, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([URLString isKindOfClass:[NSString class]]) {
            NSURL *URL = [NSURL URLWithString:URLString];
            if ([URL isKindOfClass:[NSURL class]]) {
                FYFontModel *model = [[FYFontModel alloc] init];
                model.type = type;
                model.downloadURL = URL;
                NSString *cachePath = [[FYFontCache sharedFontCache] cachedFilePathWithDownloadURL:URL];
                if (cachePath) {
                    model.status = FYFontModelDownloadStatusDownloaded;
                    model.downloadProgress = 1.0f;
                }
                [fontModelArray addObject:model];
            }
        }
    }];
    return [fontModelArray copy];
}

#pragma mark - Public

+ (void)setFontURLStringArray:(NSArray<NSString *> *)URLStringArray {
    FYFontModelCenter *center = [FYFontModelCenter defaultCenter];
    center.fontURLStringArray = URLStringArray;
    [center.fontModelArray setArray:[self assembleModelArrayWithURLStringArray:center.fontURLStringArray
                                                                          type:FYFontTypeFont]];
}

+ (void)setBoldFontURLStringArray:(NSArray<NSString *> *)URLStringArray{
    FYFontModelCenter *center = [FYFontModelCenter defaultCenter];
    center.boldFontURLStringArray = URLStringArray;
    [center.boldFontModelArray setArray:[self assembleModelArrayWithURLStringArray:center.boldFontURLStringArray
                                                                              type:FYFontTypeBoldFont]];
}

+ (void)setItalicFontURLStringArray:(NSArray<NSString *> *)URLStringArray{
    FYFontModelCenter *center = [FYFontModelCenter defaultCenter];
    center.italicFontURLStringArray = URLStringArray;
    [center.italicFontModelArray setArray:[self assembleModelArrayWithURLStringArray:center.italicFontURLStringArray
                                                                                type:FYFontTypeItalicFont]];
}

+ (NSMutableArray<FYFontModel *> *)fontModelArray {
    return [FYFontModelCenter defaultCenter].fontModelArray;
}

+ (NSMutableArray<FYFontModel *> *)boldFontModelArray {
    return [FYFontModelCenter defaultCenter].boldFontModelArray;
}

+ (NSMutableArray<FYFontModel *> *)italicFontModelArray {
    return [FYFontModelCenter defaultCenter].italicFontModelArray;
}

+ (FYFontModel *)fontModelWithURLString:(NSString *)downloadURLString {
    FYFontModelCenter *center = [FYFontModelCenter defaultCenter];
    for (NSInteger i = 0; i < center.fontModelContainer.count; i++) {
        NSMutableArray<FYFontModel *> *fontModelArray = center.fontModelContainer[i];
        for (NSInteger j = 0; j < fontModelArray.count; j++) {
            FYFontModel *model = fontModelArray[j];
            if ([model.downloadURL.absoluteString isEqualToString:downloadURLString]) {
                return model;
            }
        }
    }
    return nil;
}

+ (NSUInteger)indexOfModel:(FYFontModel *)model {
    FYFontModelCenter *center = [FYFontModelCenter defaultCenter];
    NSMutableArray<FYFontModel *> *fontModelArray = center.fontModelContainer[model.type];
    return [fontModelArray indexOfObject:model];
}

#pragma mark - Accessor

+ (NSArray<NSString *> *)URLStrings {
    
}

@end
