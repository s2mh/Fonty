
//
//  FYSelectFontTableViewCell.m
//  Fonty
//
//  Created by 颜为晨 on 9/9/16.
//  Copyright © 2016 颜为晨. All rights reserved.
//

#import "FYSelectFontTableViewCell.h"

@interface FYSelectFontTableViewCell ()

@property (nonatomic, strong) CAShapeLayer *downloadProgressLayer;

@end

@implementation FYSelectFontTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        
        _downloadProgressLayer = [CAShapeLayer layer];
        _downloadProgressLayer.fillColor = [UIColor grayColor].CGColor;
        _downloadProgressLayer.opacity = 0.5f;
        [self.layer addSublayer:_downloadProgressLayer];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGRect downloadProgressLayerFrame = self.bounds;
    CGFloat width = self.bounds.size.width;
    downloadProgressLayerFrame.origin.x = width * self.downloadProgress;
    downloadProgressLayerFrame.size.width = width * (1.0f - self.downloadProgress);
    
    UIBezierPath *downloadProgressLayerPath = [UIBezierPath bezierPathWithRect:downloadProgressLayerFrame];
    self.downloadProgressLayer.path = downloadProgressLayerPath.CGPath;
}

@end
