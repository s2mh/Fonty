
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
@property (nonatomic, strong) CALayer *stripesLayer;

@end

@implementation FYSelectFontTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        _striped = NO;
        _stripedPause = NO;
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
    if (self.striped) {
        if (![self.stripesLayer animationForKey:@"position"]) {
            [self animateStripes];
        } else {
            if (self.stripedPause) {
                [self pauseLayer:self.stripesLayer];
            } else {
                [self resumeLayer:self.stripesLayer];
            }
        }
    } else {
        [self.stripesLayer removeFromSuperlayer];
        CGFloat width = self.bounds.size.width;
        downloadProgressLayerFrame.origin.x = width * self.downloadProgress;
        downloadProgressLayerFrame.size.width = width * (1.0f - self.downloadProgress);
    }
    
    UIBezierPath *downloadProgressLayerPath = [UIBezierPath bezierPathWithRect:downloadProgressLayerFrame];
    self.downloadProgressLayer.path = downloadProgressLayerPath.CGPath;
}

- (void)animateStripes {
    CGFloat stripeWidth = self.bounds.size.height / 4.0f;
    
    self.stripesLayer.frame = CGRectMake(0.0f, 0.0f, self.bounds.size.width + (4 * stripeWidth), self.bounds.size.height);
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"position"];
    animation.duration = 0.6f;
    animation.repeatCount = HUGE_VALF;
    animation.removedOnCompletion = NO;
    animation.fromValue = [NSValue valueWithCGPoint:CGPointMake(- (2 * stripeWidth) + (self.bounds.size.width / 2.0f), self.bounds.size.height / 2.0f)];
    animation.toValue = [NSValue valueWithCGPoint:CGPointMake(0 + (self.bounds.size.width / 2.0f), self.bounds.size.height / 2.0f)];
    [self.stripesLayer addAnimation:animation forKey:@"position"];
    [self.downloadProgressLayer addSublayer:self.stripesLayer];
}

- (void)pauseLayer:(CALayer *)layer {
    if (layer.speed == 0.0f) {
        return;
    }
    CFTimeInterval pausedTime = [layer convertTime:CACurrentMediaTime() fromLayer:nil];
    layer.speed = 0.0f;
    layer.timeOffset = pausedTime;
}

- (void)resumeLayer:(CALayer *)layer {
    if (layer.speed != 0.0f) {
        return;
    }
    CFTimeInterval pausedTime = [layer timeOffset];
    layer.speed = 1.0f;
    layer.timeOffset = 0.0f;
    layer.beginTime = 0.0f;
    CFTimeInterval timeSincePause = [layer convertTime:CACurrentMediaTime() fromLayer:nil] - pausedTime;
    layer.beginTime = timeSincePause;
}

#pragma mark - Accessor

- (CALayer *)stripesLayer {
    if (!_stripesLayer) {
        _stripesLayer = [CALayer layer];
        
        CGFloat stripeWidth = self.bounds.size.height / 4.0f;
        
        UIGraphicsBeginImageContextWithOptions(CGSizeMake(stripeWidth * 4, stripeWidth * 4), NO, [UIScreen mainScreen].scale);
        
        //Fill the background
        [[UIColor clearColor] setFill];
        UIBezierPath *fillPath = [UIBezierPath bezierPathWithRect:CGRectMake(0.0f, 0.0f, stripeWidth * 4, stripeWidth * 4)];
        [fillPath fill];
        
        //Draw the stripes
        [[UIColor whiteColor] setFill];
        for (int i = 0; i < 4; i++) {
            //Create the four inital points of the fill shape
            CGPoint bottomLeft = CGPointMake(-(stripeWidth * 4), stripeWidth * 4);
            CGPoint topLeft = CGPointMake(0.0f, 0.0f);
            CGPoint topRight = CGPointMake(stripeWidth, 0.0f);
            CGPoint bottomRight = CGPointMake(-(stripeWidth * 4) + stripeWidth, stripeWidth * 4);
            //Shift all four points as needed to draw all four stripes
            bottomLeft.x += i * (2.0f * stripeWidth);
            topLeft.x += i * (2.0f * stripeWidth);
            topRight.x += i * (2.0f * stripeWidth);
            bottomRight.x += i * (2.0f * stripeWidth);
            //Create the fill path
            UIBezierPath *path = [UIBezierPath bezierPath];
            [path moveToPoint:bottomLeft];
            [path addLineToPoint:topLeft];
            [path addLineToPoint:topRight];
            [path addLineToPoint:bottomRight];
            [path closePath];
            [path fill];
        }
        
        //Retreive the image
        UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        //Set the background of the progress layer
        self.stripesLayer.backgroundColor = [UIColor colorWithPatternImage:image].CGColor;
    }
    return _stripesLayer;
}



@end
