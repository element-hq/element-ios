/*
 Copyright 2016 OpenMarket Ltd
 Copyright 2017 Vector Creations Ltd
 Copyright 2019 New Vector Ltd

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

#import "ThemeService.h"

#ifdef IS_SHARE_EXTENSION
#import "RiotShareExtension-Swift.h"
#else
#import "Riot-Swift.h"
#endif


NSString *const kThemeServiceDidChangeThemeNotification = @"kThemeServiceDidChangeThemeNotification";

// Riot Colors
UIColor *kRiotColorPinkRed;
UIColor *kRiotColorRed;
UIColor *kRiotColorBlue;
UIColor *kRiotColorCuriousBlue;
UIColor *kRiotColorIndigo;
UIColor *kRiotColorOrange;


NSInteger const kRiotRoomModeratorLevel = 50;
NSInteger const kRiotRoomAdminLevel = 100;

@implementation ThemeService

+ (ThemeService *)shared
{
    static ThemeService *sharedOnceInstance;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedOnceInstance = [ThemeService new];
    });
    
    return sharedOnceInstance;
}

- (NSString*)themeId
{
    // Retrieve the current selected theme ("light" if none. "auto" is used as default from iOS 11).
    NSString *themeId = RiotSettings.shared.userInterfaceTheme;

    if (!themeId || [themeId isEqualToString:@"auto"])
    {
        themeId = UIAccessibilityIsInvertColorsEnabled() ? @"dark" : @"light";
    }

    return themeId;
}

- (id<Theme>)themeWithThemeId:(NSString*)themeId
{
    // Use light theme colors by default.
    id<Theme> theme = DefaultTheme.shared;

    if ([themeId isEqualToString:@"dark"])
    {
        // Set dark theme colors
        theme = DarkTheme.shared;
    }
    else if ([themeId isEqualToString:@"black"])
    {
        // TODO: Use dark theme colors for the moment
        theme = DarkTheme.shared;
    }

    return theme;
}

#pragma mark - Private methods

+ (void)load
{
    [super load];

    // Load colors at the app load time for the life of the app

    // Colors as defined by the design
    kRiotColorPinkRed = UIColorFromRGB(0xFF0064);
    kRiotColorRed = UIColorFromRGB(0xFF4444);
    kRiotColorBlue = UIColorFromRGB(0x81BDDB);
    kRiotColorCuriousBlue = UIColorFromRGB(0x2A9EDB);
    kRiotColorIndigo = UIColorFromRGB(0xBD79CC);
    kRiotColorOrange = UIColorFromRGB(0xF8A15F);

    ThemeService *themeService = ThemeService.shared;

    // Observe user interface theme change.
    [[NSUserDefaults standardUserDefaults] addObserver:themeService forKeyPath:@"userInterfaceTheme" options:0 context:nil];
    [themeService userInterfaceThemeDidChange];

    // Observe "Invert Colours" settings changes (available since iOS 11)
    [[NSNotificationCenter defaultCenter] addObserver:themeService selector:@selector(accessibilityInvertColorsStatusDidChange) name:UIAccessibilityInvertColorsStatusDidChangeNotification object:nil];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([@"userInterfaceTheme" isEqualToString:keyPath])
    {
        [self userInterfaceThemeDidChange];
    }
}

- (void)accessibilityInvertColorsStatusDidChange
{
    // Refresh the theme only for "auto"
    NSString *theme = RiotSettings.shared.userInterfaceTheme;
    if (!theme || [theme isEqualToString:@"auto"])
    {
        [self userInterfaceThemeDidChange];
    }
}

- (void)userInterfaceThemeDidChange
{
    // Update the current theme
    _theme = [self themeWithThemeId:self.themeId];
    
    [UIScrollView appearance].indicatorStyle = self.theme.scrollBarStyle;

    [[NSNotificationCenter defaultCenter] postNotificationName:kThemeServiceDidChangeThemeNotification object:nil];
}

@end
