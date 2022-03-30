// 
// Copyright 2022 New Vector Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

#import "PresenceIndicatorView.h"
#import "ThemeService.h"

#import "GeneratedInterface-Swift.h"

@interface PresenceIndicatorView()

@property (nonatomic) CALayer *borderLayer;

@end

@implementation PresenceIndicatorView

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self)
    {
        [self setup];
    }
    return self;
}

- (void)setup
{
    self.layer.cornerRadius = self.frame.size.width / 2.f;
    self.borderLayer = [[CALayer alloc] init];
    self.borderLayer.borderWidth = 2.5;
    [self.layer addSublayer:self.borderLayer];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    self.borderLayer.cornerRadius = self.layer.cornerRadius + 1;
    self.borderLayer.frame = CGRectMake(-1,
                                   -1,
                                   self.frame.size.width + 2,
                                   self.frame.size.height +2);
}

- (void)setPresence:(MXPresence)presence
{
    switch (presence) {
        case MXPresenceOnline:
            self.backgroundColor = ThemeService.shared.theme.tintColor;
            self.borderLayer.borderColor = ThemeService.shared.theme.backgroundColor.CGColor;
            break;
        case MXPresenceOffline:
        case MXPresenceUnavailable:
            self.backgroundColor = ThemeService.shared.theme.tabBarUnselectedItemTintColor;
            self.borderLayer.borderColor = ThemeService.shared.theme.backgroundColor.CGColor;
            break;
        default:
            self.backgroundColor = UIColor.clearColor;
            self.borderLayer.borderColor = UIColor.clearColor.CGColor;
            break;
    }
}

@end
