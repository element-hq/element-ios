/*
Copyright 2024 New Vector Ltd.
Copyright 2015 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "MXKPieChartView.h"

@interface MXKPieChartView ()
{
    // graphical items
    CAShapeLayer* backgroundContainerLayer;
    CAShapeLayer* powerContainerLayer;
}
@end

@implementation MXKPieChartView

- (void)setProgress:(CGFloat)progress
{
    // Consider only positive progress value
    if (progress <= 0)
    {
        _progress = 0;
        self.hidden = YES;
    }
    else
    {
        // Ensure that the progress value does not excceed 1.0
        _progress = MIN(progress, 1.0);
        self.hidden = NO;
    }
    
    // defines the view settings
    CGFloat radius = self.frame.size.width / 2;
    
    // draw a rounded view
    [self.layer setCornerRadius:radius];
    self.backgroundColor = [UIColor clearColor];
    
    // draw the pie
    CALayer* layer = [self layer];
    
    // remove any previous drawn layer
    if (powerContainerLayer)
    {
        [powerContainerLayer removeFromSuperlayer];
        powerContainerLayer = nil;
    }
    
    // define default colors
    if (!_progressColor)
    {
        _progressColor = [UIColor redColor];
    }
    
    if (!_unprogressColor)
    {
        _unprogressColor = [UIColor lightGrayColor];
    }
    
    // the background cell color is hidden the cell is selected.
    // so put in grey the cell background triggers a weird display (the background grey is hidden but not the red part).
    // add an other layer fixes the UX.
    if (!backgroundContainerLayer)
    {
        backgroundContainerLayer = [CAShapeLayer layer];
        [backgroundContainerLayer setZPosition:0];
        [backgroundContainerLayer setStrokeColor:NULL];
        backgroundContainerLayer.fillColor = _unprogressColor.CGColor;
        
        // build the path
        CGMutablePathRef path = CGPathCreateMutable();
        CGPathMoveToPoint(path, NULL, radius, radius);
        
        CGPathAddArc(path, NULL, radius, radius, radius, 0 , 2 * M_PI, 0);
        CGPathCloseSubpath(path);
        
        [backgroundContainerLayer setPath:path];
        CFRelease(path);
        
        // add the sub layer
        [layer addSublayer:backgroundContainerLayer];
    }
    
    if (_progress)
    {
        // create the filled layer
        powerContainerLayer = [CAShapeLayer layer];
        [powerContainerLayer setZPosition:0];
        [powerContainerLayer setStrokeColor:NULL];
        
        // power level is drawn in red
        powerContainerLayer.fillColor = _progressColor.CGColor;
        
        // build the path
        CGMutablePathRef path = CGPathCreateMutable();
        CGPathMoveToPoint(path, NULL, radius, radius);
        
        CGPathAddArc(path, NULL, radius, radius, radius, -M_PI / 2, (_progress * 2 * M_PI) - (M_PI / 2), 0);
        CGPathCloseSubpath(path);
        
        [powerContainerLayer setPath:path];
        CFRelease(path);
        
        // add the sub layer
        [layer addSublayer:powerContainerLayer];
    }
}

- (void)setProgressColor:(UIColor *)progressColor
{
    _progressColor = progressColor;
    self.progress = _progress;
}

- (void)setUnprogressColor:(UIColor *)unprogressColor
{
    _unprogressColor = unprogressColor;
    
    if (backgroundContainerLayer)
    {
        [backgroundContainerLayer removeFromSuperlayer];
        backgroundContainerLayer = nil;
    }
    self.progress = _progress;
}

@end