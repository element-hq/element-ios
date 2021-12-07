/*
 Copyright 2017 Aram Sargsyan
 
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
