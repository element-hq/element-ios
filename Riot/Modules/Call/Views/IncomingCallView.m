/*
Copyright 2018-2024 New Vector Ltd.
Copyright 2017 Vector Creations Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "IncomingCallView.h"

#import "MatrixKit.h"
#import <MatrixSDK/MXMediaManager.h>

#import "CircleButton.h"
#import "ThemeService.h"
#import "GeneratedInterface-Swift.h"

static const CGFloat kAvatarSize = 100.0;
static const CGFloat kButtonSize = 80.0;

@interface IncomingCallView ()

@property (nonatomic) MXKImageView *callerImageView;
@property (nonatomic) UILabel *callerNameLabel;
@property (nonatomic) UILabel *callInfoLabel;

@property (nonatomic) CircleButton *answerButton;
@property (nonatomic) UILabel *answerTitleLabel;

@property (nonatomic) CircleButton *rejectButton;
@property (nonatomic) UILabel *rejectTitleLabel;

@end

@implementation IncomingCallView

+ (CGSize)callerAvatarSize
{
    return CGSizeMake(kAvatarSize, kAvatarSize);
}

- (instancetype)initWithCallerAvatar:(NSString *)mxcAvatarURI
                        mediaManager:(MXMediaManager *)mediaManager
                    placeholderImage:(UIImage *)placeholderImage
                          callerName:(NSString *)callerName
                            callInfo:(NSString *)callInfo
{
    self = [super initWithFrame:CGRectZero];
    if (self)
    {
        self.backgroundColor = ThemeService.shared.theme.backgroundColor;
        self.opaque = YES;
        
        self.callerImageView = [[MXKImageView alloc] init];
        self.callerImageView.backgroundColor = ThemeService.shared.theme.backgroundColor;
        self.callerImageView.clipsToBounds = YES;
        self.callerImageView.mediaFolder = kMXMediaManagerAvatarThumbnailFolder;
        self.callerImageView.enableInMemoryCache = YES;
        [self.callerImageView setImageURI:mxcAvatarURI
                                 withType:nil
                      andImageOrientation:UIImageOrientationUp
                            toFitViewSize:IncomingCallView.callerAvatarSize
                               withMethod:MXThumbnailingMethodCrop
                             previewImage:placeholderImage
                             mediaManager:mediaManager];
        
        self.callerNameLabel = [[UILabel alloc] init];
        self.callerNameLabel.backgroundColor = ThemeService.shared.theme.backgroundColor;
        self.callerNameLabel.textColor = ThemeService.shared.theme.textPrimaryColor;
        self.callerNameLabel.font = [UIFont systemFontOfSize:24.0 weight:UIFontWeightMedium];
        self.callerNameLabel.text = callerName;
        self.callerNameLabel.textAlignment = NSTextAlignmentCenter;
        
        self.callInfoLabel = [[UILabel alloc] init];
        self.callInfoLabel.backgroundColor = ThemeService.shared.theme.backgroundColor;
        self.callInfoLabel.textColor = ThemeService.shared.theme.textSecondaryColor;
        self.callInfoLabel.font = [UIFont systemFontOfSize:18.0 weight:UIFontWeightRegular];
        self.callInfoLabel.text = callInfo;
        self.callInfoLabel.textAlignment = NSTextAlignmentCenter;
        
        UIColor *answerButtonBorderColor = ThemeService.shared.theme.tintColor;
        
        self.answerButton = [[CircleButton alloc] initWithImage:AssetImages.voiceCallHangonIcon.image
                                                    borderColor:answerButtonBorderColor];
        self.answerButton.defaultBackgroundColor = ThemeService.shared.theme.backgroundColor;
        self.answerButton.tintColor = answerButtonBorderColor;
        [self.answerButton addTarget:self action:@selector(didTapAnswerButton) forControlEvents:UIControlEventTouchUpInside];
        
        self.answerTitleLabel = [[UILabel alloc] init];
        self.answerTitleLabel.backgroundColor = ThemeService.shared.theme.backgroundColor;        
        self.answerTitleLabel.textColor = answerButtonBorderColor;
        self.answerTitleLabel.font = [UIFont systemFontOfSize:18.0 weight:UIFontWeightRegular];
        self.answerTitleLabel.text = [VectorL10n accept];
        
        UIColor *rejectButtonBorderColor = ThemeService.shared.theme.warningColor;
        
        self.rejectButton = [[CircleButton alloc] initWithImage:AssetImages.voiceCallHangupIcon.image
                                                    borderColor:rejectButtonBorderColor];
        self.rejectButton.defaultBackgroundColor = ThemeService.shared.theme.backgroundColor;
        self.rejectButton.tintColor = rejectButtonBorderColor;
        [self.rejectButton addTarget:self action:@selector(didTapRejectButton) forControlEvents:UIControlEventTouchUpInside];
        
        self.rejectTitleLabel = [[UILabel alloc] init];
        self.rejectTitleLabel.backgroundColor = ThemeService.shared.theme.backgroundColor;
        self.rejectTitleLabel.textColor = rejectButtonBorderColor;
        self.rejectTitleLabel.font = [UIFont systemFontOfSize:18.0 weight:UIFontWeightRegular];
        self.rejectTitleLabel.text = [VectorL10n decline];

        [self setupLayout];
    }
    
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    self.callerImageView.layer.cornerRadius = CGRectGetWidth(self.callerImageView.bounds) / 2.0;
}

- (void)setupLayout
{
    NSArray *views = @[self.callerImageView, self.callerNameLabel, self.callInfoLabel, self.answerButton, self.answerTitleLabel, self.rejectButton, self.rejectTitleLabel];
    for (UIView *view in views)
    {
        view.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:view];
    }
    
    [NSLayoutConstraint activateConstraints:@[
                                              [NSLayoutConstraint constraintWithItem:self.callerImageView
                                                                           attribute:NSLayoutAttributeTop
                                                                           relatedBy:NSLayoutRelationEqual
                                                                              toItem:self
                                                                           attribute:NSLayoutAttributeTop
                                                                          multiplier:1.0
                                                                            constant:62.0],
                                              
                                              [NSLayoutConstraint constraintWithItem:self.callerImageView
                                                                           attribute:NSLayoutAttributeCenterX
                                                                           relatedBy:NSLayoutRelationEqual
                                                                              toItem:self
                                                                           attribute:NSLayoutAttributeCenterX
                                                                          multiplier:1.0
                                                                            constant:0.0],
                                              
                                              [NSLayoutConstraint constraintWithItem:self.callerImageView
                                                                           attribute:NSLayoutAttributeWidth
                                                                           relatedBy:NSLayoutRelationEqual
                                                                              toItem:nil
                                                                           attribute:NSLayoutAttributeNotAnAttribute
                                                                          multiplier:1.0
                                                                            constant:kAvatarSize],
                                              
                                              [NSLayoutConstraint constraintWithItem:self.callerImageView
                                                                           attribute:NSLayoutAttributeHeight
                                                                           relatedBy:NSLayoutRelationEqual
                                                                              toItem:self.callerImageView
                                                                           attribute:NSLayoutAttributeWidth
                                                                          multiplier:1.0
                                                                            constant:0.0],
                                              
                                              [NSLayoutConstraint constraintWithItem:self.callerNameLabel
                                                                           attribute:NSLayoutAttributeTop
                                                                           relatedBy:NSLayoutRelationEqual
                                                                              toItem:self.callerImageView
                                                                           attribute:NSLayoutAttributeBottom
                                                                          multiplier:1.0
                                                                            constant:18.0],
                                              
                                              [NSLayoutConstraint constraintWithItem:self.callerNameLabel
                                                                           attribute:NSLayoutAttributeLeading
                                                                           relatedBy:NSLayoutRelationEqual
                                                                              toItem:self
                                                                           attribute:NSLayoutAttributeLeading
                                                                          multiplier:1.0
                                                                            constant:15.0],
                                              
                                              [NSLayoutConstraint constraintWithItem:self.callerNameLabel
                                                                           attribute:NSLayoutAttributeTrailing
                                                                           relatedBy:NSLayoutRelationEqual
                                                                              toItem:self
                                                                           attribute:NSLayoutAttributeTrailing
                                                                          multiplier:1.0
                                                                            constant:-15.0],
                                              
                                              [NSLayoutConstraint constraintWithItem:self.callInfoLabel
                                                                           attribute:NSLayoutAttributeTop
                                                                           relatedBy:NSLayoutRelationEqual
                                                                              toItem:self.callerNameLabel
                                                                           attribute:NSLayoutAttributeBottom
                                                                          multiplier:1.0
                                                                            constant:7.0],
                                              
                                              [NSLayoutConstraint constraintWithItem:self.callInfoLabel
                                                                           attribute:NSLayoutAttributeCenterX
                                                                           relatedBy:NSLayoutRelationEqual
                                                                              toItem:self
                                                                           attribute:NSLayoutAttributeCenterX
                                                                          multiplier:1.0
                                                                            constant:0.0],
                                              
                                              [NSLayoutConstraint constraintWithItem:self.callInfoLabel
                                                                           attribute:NSLayoutAttributeWidth
                                                                           relatedBy:NSLayoutRelationEqual
                                                                              toItem:self.callerNameLabel
                                                                           attribute:NSLayoutAttributeWidth
                                                                          multiplier:1.0
                                                                            constant:0.0],
                                              
                                              [NSLayoutConstraint constraintWithItem:self.rejectButton
                                                                           attribute:NSLayoutAttributeWidth
                                                                           relatedBy:NSLayoutRelationEqual
                                                                              toItem:nil
                                                                           attribute:NSLayoutAttributeNotAnAttribute
                                                                          multiplier:1.0
                                                                            constant:kButtonSize],
                                              
                                              [NSLayoutConstraint constraintWithItem:self.rejectButton
                                                                           attribute:NSLayoutAttributeHeight
                                                                           relatedBy:NSLayoutRelationEqual
                                                                              toItem:self.rejectButton
                                                                           attribute:NSLayoutAttributeWidth
                                                                          multiplier:1.0
                                                                            constant:0.0],
                                              
                                              [NSLayoutConstraint constraintWithItem:self.rejectButton
                                                                           attribute:NSLayoutAttributeTrailing
                                                                           relatedBy:NSLayoutRelationEqual
                                                                              toItem:self
                                                                           attribute:NSLayoutAttributeCenterX
                                                                          multiplier:1.0
                                                                            constant:-22.5],
                                              
                                              [NSLayoutConstraint constraintWithItem:self.rejectTitleLabel
                                                                           attribute:NSLayoutAttributeTop
                                                                           relatedBy:NSLayoutRelationEqual
                                                                              toItem:self.rejectButton
                                                                           attribute:NSLayoutAttributeBottom
                                                                          multiplier:1.0
                                                                            constant:8.0],
                                              
                                              [NSLayoutConstraint constraintWithItem:self.rejectTitleLabel
                                                                           attribute:NSLayoutAttributeCenterX
                                                                           relatedBy:NSLayoutRelationEqual
                                                                              toItem:self.rejectButton
                                                                           attribute:NSLayoutAttributeCenterX
                                                                          multiplier:1.0
                                                                            constant:0.0],
                                              
                                              [NSLayoutConstraint constraintWithItem:self.rejectTitleLabel
                                                                           attribute:NSLayoutAttributeBottom
                                                                           relatedBy:NSLayoutRelationEqual
                                                                              toItem:self
                                                                           attribute:NSLayoutAttributeBottom
                                                                          multiplier:1.0
                                                                            constant:-16.0],
                                              
                                              [NSLayoutConstraint constraintWithItem:self.answerButton
                                                                           attribute:NSLayoutAttributeWidth
                                                                           relatedBy:NSLayoutRelationEqual
                                                                              toItem:nil
                                                                           attribute:NSLayoutAttributeNotAnAttribute
                                                                          multiplier:1.0
                                                                            constant:kButtonSize],
                                              
                                              [NSLayoutConstraint constraintWithItem:self.answerButton
                                                                           attribute:NSLayoutAttributeHeight
                                                                           relatedBy:NSLayoutRelationEqual
                                                                              toItem:self.answerButton
                                                                           attribute:NSLayoutAttributeWidth
                                                                          multiplier:1.0
                                                                            constant:0.0],
                                              
                                              [NSLayoutConstraint constraintWithItem:self.answerButton
                                                                           attribute:NSLayoutAttributeLeading
                                                                           relatedBy:NSLayoutRelationEqual
                                                                              toItem:self
                                                                           attribute:NSLayoutAttributeCenterX
                                                                          multiplier:1.0
                                                                            constant:22.5],
                                              
                                              [NSLayoutConstraint constraintWithItem:self.answerTitleLabel
                                                                           attribute:NSLayoutAttributeTop
                                                                           relatedBy:NSLayoutRelationEqual
                                                                              toItem:self.answerButton
                                                                           attribute:NSLayoutAttributeBottom
                                                                          multiplier:1.0
                                                                            constant:8.0],
                                              
                                              [NSLayoutConstraint constraintWithItem:self.answerTitleLabel
                                                                           attribute:NSLayoutAttributeCenterX
                                                                           relatedBy:NSLayoutRelationEqual
                                                                              toItem:self.answerButton
                                                                           attribute:NSLayoutAttributeCenterX
                                                                          multiplier:1.0
                                                                            constant:0.0],
                                              
                                              [NSLayoutConstraint constraintWithItem:self.answerTitleLabel
                                                                           attribute:NSLayoutAttributeBottom
                                                                           relatedBy:NSLayoutRelationEqual
                                                                              toItem:self
                                                                           attribute:NSLayoutAttributeBottom
                                                                          multiplier:1.0
                                                                            constant:-16.0]
                                              ]];
}

// MARK: - Actions

- (void)didTapAnswerButton
{
    if (self.onAnswer)
    {
        self.onAnswer();
    }
}

- (void)didTapRejectButton
{
    if (self.onReject)
    {
        self.onReject();
    }
}

@end
