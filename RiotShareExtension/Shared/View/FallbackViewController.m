/*
Copyright 2024 New Vector Ltd.
Copyright 2017 Aram Sargsyan

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "FallbackViewController.h"
#import "ThemeService.h"

#import "GeneratedInterface-Swift.h"

@interface FallbackViewController ()

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UIImageView *logoImageView;

@end

@implementation FallbackViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = ThemeService.shared.theme.backgroundColor;
    self.titleLabel.textColor = ThemeService.shared.theme.textSecondaryColor;
    self.titleLabel.text = [VectorL10n shareExtensionAuthPrompt];
    self.logoImageView.tintColor = ThemeService.shared.theme.tintColor;
}

@end
