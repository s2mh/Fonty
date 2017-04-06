//
//  FYSelectFontTableViewCell.m
//  Fonty
//
//  Created by 颜为晨 on 9/9/16.
//  Copyright © 2016 颜为晨. All rights reserved.
//

#import "FYSelectFontTableViewCell.h"

static const CGFloat StripeWidth = 20.0f;

@interface FYSelectFontTableViewCell ()

@property (nonatomic, strong) CALayer *stripesLayer;
@property (nonatomic, strong) CAShapeLayer *progressLayer;

@end

@implementation FYSelectFontTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        _striped = NO;
        _pauseStripes = NO;
        self.textLabel.lineBreakMode = NSLineBreakByTruncatingMiddle;
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    if (self.downloadProgress == 1.0f) {
        [_stripesLayer removeFromSuperlayer];
        [_progressLayer removeFromSuperlayer];
        return;
    }
    if (self.striped) {
        [_progressLayer removeFromSuperlayer];
        [self.layer addSublayer:self.stripesLayer];
        if (self.pauseStripes) {
            [self pauseLayer:self.stripesLayer];
        } else {
            [self resumeLayer:self.stripesLayer];
        }
    } else {
        [_stripesLayer removeFromSuperlayer];
        [self.layer addSublayer:self.progressLayer];
        if (self.pauseStripes) {
            [self resumeLayer:self.progressLayer];
        } else {
            [self pauseLayer:self.progressLayer];
        }
    }
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
    if (selected) {
        self.accessoryType = UITableViewCellAccessoryCheckmark;
    } else {
        self.accessoryType = UITableViewCellAccessoryNone;
    }
}

#pragma mark - Private

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
    layer.beginTime = 0.0;
    CFTimeInterval timeSincePause = [layer convertTime:CACurrentMediaTime() fromLayer:nil] - pausedTime;
    layer.beginTime = timeSincePause;
}

#pragma mark - Accessor

- (CALayer *)stripesLayer {
    if (!_stripesLayer) {
        _stripesLayer = [CAShapeLayer layer];
        _stripesLayer.frame = CGRectMake(0.0f, 0.0f, self.bounds.size.width + (4 * StripeWidth), self.bounds.size.height);
        _stripesLayer.opacity = 0.5f;
        
        UIGraphicsBeginImageContextWithOptions(CGSizeMake(StripeWidth * 4, StripeWidth * 4), NO, [UIScreen mainScreen].scale);
        //Fill the background
        [[UIColor clearColor] setFill];
        UIBezierPath *fillPath = [UIBezierPath bezierPathWithRect:CGRectMake(0.0f, 0.0f, StripeWidth * 4, StripeWidth * 4)];
        [fillPath fill];
        //Draw the stripes
        [[UIColor grayColor] setFill];
        for (int i = 0; i < 4; i++) {
            //Create the four inital points of the fill shape
            CGPoint bottomLeft  = CGPointMake(-(StripeWidth * 4), StripeWidth * 4);
            CGPoint topLeft     = CGPointMake(0.0f, 0.0f);
            CGPoint topRight    = CGPointMake(StripeWidth, 0.0f);
            CGPoint bottomRight = CGPointMake(-(StripeWidth * 4) + StripeWidth, StripeWidth * 4);
            //Shift all four points as needed to draw all four stripes
            bottomLeft.x  += i * (2.0f * StripeWidth);
            topLeft.x     += i * (2.0f * StripeWidth);
            topRight.x    += i * (2.0f * StripeWidth);
            bottomRight.x += i * (2.0f * StripeWidth);
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
        _stripesLayer.backgroundColor = [UIColor colorWithPatternImage:image].CGColor;
        
        CABasicAnimation *stripedAnimation = [CABasicAnimation animationWithKeyPath:@"position"];
        stripedAnimation.duration = 0.6f;
        stripedAnimation.repeatCount = HUGE_VALF;
        stripedAnimation.removedOnCompletion = NO;
        stripedAnimation.fromValue = [NSValue valueWithCGPoint:CGPointMake(- (2 * StripeWidth) + (self.bounds.size.width / 2.0f), self.bounds.size.height / 2.0f)];
        stripedAnimation.toValue = [NSValue valueWithCGPoint:CGPointMake(0 + (self.bounds.size.width / 2.0f), self.bounds.size.height / 2.0f)];
        
        [_stripesLayer addAnimation:stripedAnimation forKey:@"stripedAnimation"];
    }
    return _stripesLayer;
}

- (CAShapeLayer *)progressLayer {
    if (!_progressLayer) {
        _progressLayer = [CAShapeLayer layer];
        _progressLayer.fillColor = [UIColor grayColor].CGColor;
        _progressLayer.path = [UIBezierPath bezierPathWithRect:self.bounds].CGPath;
        _progressLayer.opacity = 0.5f;
        
        CABasicAnimation *flicker = [CABasicAnimation animationWithKeyPath:@"fillColor"];
        flicker.duration = 0.95;
        flicker.repeatCount = HUGE_VALF;
        flicker.removedOnCompletion = NO;
        flicker.autoreverses = YES;
        flicker.toValue = (id)[UIColor lightGrayColor].CGColor;
        flicker.fromValue = (id)[UIColor grayColor].CGColor;
        [_progressLayer addAnimation:flicker forKey:@"flicker"];
    }
    return _progressLayer;
}

- (void)setDownloadProgress:(double)downloadProgress {
    if (_downloadProgress != downloadProgress) {
        _downloadProgress = downloadProgress;
        CGRect frame = self.bounds;
        CGFloat width = frame.size.width;
        frame.origin.x = width * downloadProgress;
        frame.size.width =  width * (1.0f - downloadProgress);
        _progressLayer.path = [UIBezierPath bezierPathWithRect:frame].CGPath;
    }
}

@end
