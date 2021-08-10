//
//  SCSegmentControlLineIndicator.h
//  SCSegmentControl
//
//  Created by ty.Chen on 2020/11/18.
//

#import <UIKit/UIKit.h>

@interface SCSegmentControlLineIndicator : UIView

@property (nonatomic, strong) CALayer *indicatorLayer;

@property (nonatomic, strong) UIView *indicatorView;

@property (nonatomic, strong) UIImage *indicatorImage;

@property (nonatomic, assign) UIViewContentMode indicatorImageViewMode;

@end


