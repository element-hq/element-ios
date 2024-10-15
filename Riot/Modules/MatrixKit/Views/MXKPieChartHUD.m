/*
Copyright 2024 New Vector Ltd.
Copyright 2017 Aram Sargsyan

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "MXKPieChartHUD.h"
#import "NSBundle+MatrixKit.h"
#import "MXKPieChartView.h"

@interface MXKPieChartHUD ()

@property (weak, nonatomic) IBOutlet UIView *hudView;
@property (weak, nonatomic) IBOutlet MXKPieChartView *pieChartView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;


@end

@implementation MXKPieChartHUD

#pragma mark - Lifecycle

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        [self configureFromNib];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self)
    {
        [self configureFromNib];
    }
    return self;
}

- (void)configureFromNib
{
    NSBundle *bundle = [NSBundle mxk_bundleForClass:self.class];
    [bundle loadNibNamed:NSStringFromClass(self.class) owner:self options:nil];
    [self customizeViewRendering];
    
    self.hudView.frame = self.bounds;
    
    self.clipsToBounds = YES;
    self.layer.cornerRadius = 10.0;
    
    [self addSubview:self.hudView];
}

- (void)customizeViewRendering
{
    [super customizeViewRendering];
    
    self.pieChartView.backgroundColor = [UIColor clearColor];
    self.pieChartView.progressColor = [UIColor whiteColor];
    self.pieChartView.unprogressColor = [UIColor clearColor];
    self.pieChartView.tintColor = [UIColor whiteColor];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    [self.pieChartView.layer setCornerRadius:self.pieChartView.frame.size.width / 2];
}

#pragma mark - Public

+ (MXKPieChartHUD *)showLoadingHudOnView:(UIView *)view WithMessage:(NSString *)message
{
    MXKPieChartHUD *hud = [[MXKPieChartHUD alloc] init];
    [view addSubview:hud];
    
    hud.translatesAutoresizingMaskIntoConstraints = NO;
    
    NSLayoutConstraint *centerXConstraint = [NSLayoutConstraint constraintWithItem:hud attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:view attribute:NSLayoutAttributeCenterX multiplier:1 constant:0];
    NSLayoutConstraint *centerYConstraint = [NSLayoutConstraint constraintWithItem:hud attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:view attribute:NSLayoutAttributeCenterY multiplier:1 constant:0];
    NSLayoutConstraint *widthConstraint = [NSLayoutConstraint constraintWithItem:hud attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:160];
    NSLayoutConstraint *heightConstraint = [NSLayoutConstraint constraintWithItem:hud attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:105];
    [NSLayoutConstraint activateConstraints:@[centerXConstraint, centerYConstraint, widthConstraint, heightConstraint]];
    
    hud.titleLabel.text = message;
    
    return hud;
}

- (void)setProgress:(CGFloat)progress
{
    [UIView animateWithDuration:0.2 animations:^{
        [self.pieChartView setProgress:progress];
    }];
    
}



@end
