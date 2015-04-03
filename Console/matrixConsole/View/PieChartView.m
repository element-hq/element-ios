/*
 Copyright 2014 OpenMarket Ltd
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

#import "PieChartView.h"

@interface PieChartView () {
    // graphical items
    CAShapeLayer* backgroundContainerLayer;
    CAShapeLayer* powerContainerLayer;
    
    CGFloat _progress;
    
    UIColor* _progressColor;
    UIColor* _unprogressColor;
}
@end

@implementation PieChartView

- (void)setProgress:(CGFloat)progress {
    
    _progress = progress;
    
    // no power level -> hide the pie
    if (0 >= progress) {
        self.hidden = YES;
        return;
    }
        
    // ensure that the progress value does not excceed 1.0
    progress = MIN(progress, 1.0);

    // display it
    self.hidden = NO;

    // defines the view settings
    CGFloat radius = self.frame.size.width / 2;

    // draw a rounded view
    [self.layer setCornerRadius:radius];
    self.backgroundColor = [UIColor clearColor];

    // draw the pie
    CALayer* layer = [self layer];

    // remove any previous drawn layer
    if (powerContainerLayer) {
        [powerContainerLayer removeFromSuperlayer];
    }
    
    // define default colors
    if (!_progressColor) {
        _progressColor = [UIColor redColor];
    }

    if (!_unprogressColor) {
        _unprogressColor = [UIColor lightGrayColor];
    }
    
    // the background cell color is hidden the cell is selected.
    // so put in grey the cell background triggers a weird display (the background grey is hidden but not the red part).
    // add an other layer fixes the UX.
    if (!backgroundContainerLayer) {
        
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

    // create the red layer
    powerContainerLayer = [CAShapeLayer layer];
    [powerContainerLayer setZPosition:0];
    [powerContainerLayer setStrokeColor:NULL];

    // power level is drawn in red
    powerContainerLayer.fillColor = _progressColor.CGColor;

    // build the path
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathMoveToPoint(path, NULL, radius, radius);

    CGPathAddArc(path, NULL, radius, radius, radius, -M_PI / 2, (progress * 2 * M_PI) - (M_PI / 2), 0);
    CGPathCloseSubpath(path);

    [powerContainerLayer setPath:path];
    CFRelease(path);

    // add the sub layer
    [layer addSublayer:powerContainerLayer];
}

- (CGFloat) progress {
    return _progress;
}

- (void)setProgressColor:(UIColor *)progressColor {
    _progressColor = progressColor;
    self.progress = _progress;
}

- (UIColor*) progressColor {
    return _progressColor;
}

- (void)setUnprogressColor:(UIColor *)unprogressColor {
    _unprogressColor = unprogressColor;
    self.progress = _progress;
}

- (UIColor*) unprogressColor {
    return _unprogressColor;
}

@end