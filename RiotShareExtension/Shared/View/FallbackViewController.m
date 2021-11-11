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
