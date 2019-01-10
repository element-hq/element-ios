/*
 Copyright 2016 OpenMarket Ltd
 Copyright 2017 Vector Creations Ltd

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

#import "RiotDesignValues.h"

#ifdef IS_SHARE_EXTENSION
#import "RiotShareExtension-Swift.h"
#else
#import "Riot-Swift.h"
#endif


NSString *const kRiotDesignValuesDidChangeThemeNotification = @"kRiotDesignValuesDidChangeThemeNotification";

UIColor *kRiotSecondaryTextColor;
UIColor *kRiotPlaceholderTextColor;
UIColor *kRiotTopicTextColor;
UIColor *kRiotSelectedBgColor;
UIColor *kRiotAuxiliaryColor;
UIColor *kRiotOverlayColor;

// Riot Colors
UIColor *kRiotColorPinkRed;
UIColor *kRiotColorRed;
UIColor *kRiotColorBlue;
UIColor *kRiotColorCuriousBlue;
UIColor *kRiotColorIndigo;
UIColor *kRiotColorOrange;


NSInteger const kRiotRoomModeratorLevel = 50;
NSInteger const kRiotRoomAdminLevel = 100;

UIScrollViewIndicatorStyle kRiotScrollBarStyle;

@implementation RiotDesignValues

+ (RiotDesignValues *)sharedInstance
{
    static RiotDesignValues *sharedOnceInstance;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedOnceInstance = [[RiotDesignValues alloc] init];
    });
    
    return sharedOnceInstance;
}

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

    // Observe user interface theme change.
    [[NSUserDefaults standardUserDefaults] addObserver:[RiotDesignValues sharedInstance] forKeyPath:@"userInterfaceTheme" options:0 context:nil];
    [[RiotDesignValues sharedInstance] userInterfaceThemeDidChange];

    // Observe "Invert Colours" settings changes (available since iOS 11)
    [[NSNotificationCenter defaultCenter] addObserver:[RiotDesignValues sharedInstance] selector:@selector(accessibilityInvertColorsStatusDidChange) name:UIAccessibilityInvertColorsStatusDidChangeNotification object:nil];
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
    // Retrieve the current selected theme ("light" if none. "auto" is used as default from iOS 11).
    NSString *themeId = RiotSettings.shared.userInterfaceTheme;

    if (!themeId || [themeId isEqualToString:@"auto"])
    {
        themeId = UIAccessibilityIsInvertColorsEnabled() ? @"dark" : @"light";
    }

    if ([themeId isEqualToString:@"dark"])
    {
        // Set dark theme colors
        kRiotPlaceholderTextColor = [UIColor colorWithWhite:1.0 alpha:0.3];
        kRiotSelectedBgColor = [UIColor blackColor];

        kRiotOverlayColor = [UIColor colorWithWhite:0.3 alpha:0.5];
        
        kRiotScrollBarStyle = UIScrollViewIndicatorStyleWhite;
    }
    else if ([themeId isEqualToString:@"black"])
    {
        // Set black theme colors
        kRiotPlaceholderTextColor = [UIColor colorWithWhite:1.0 alpha:0.3];
        kRiotSelectedBgColor = [UIColor blackColor];

        kRiotOverlayColor = [UIColor colorWithWhite:0.3 alpha:0.5];

        kRiotScrollBarStyle = UIScrollViewIndicatorStyleWhite;
    }
    else
    {
        // Set light theme colors by default.
        kRiotPlaceholderTextColor = nil; // Use default 70% gray color.
        kRiotSelectedBgColor = nil; // Use the default selection color.

        kRiotOverlayColor = [UIColor colorWithWhite:0.7 alpha:0.5];

        kRiotScrollBarStyle = UIScrollViewIndicatorStyleDefault;
    }

    // Apply theme color constants
    id<Theme> theme = [RiotDesignValues theme];

    kRiotSecondaryTextColor = theme.textSecondaryColor;

    kRiotTopicTextColor = theme.baseTextSecondaryColor;
    kRiotAuxiliaryColor = theme.headerTextSecondaryColor;

    [UIScrollView appearance].indicatorStyle = kRiotScrollBarStyle;

    [[NSNotificationCenter defaultCenter] postNotificationName:kRiotDesignValuesDidChangeThemeNotification object:nil];
}

+ (id<Theme>)theme
{
    id<Theme> theme;

    // Retrieve the current selected theme ("light" if none. "auto" is used as default from iOS 11).
    NSString *themeId = RiotSettings.shared.userInterfaceTheme;

    if (!themeId || [themeId isEqualToString:@"auto"])
    {
        themeId = UIAccessibilityIsInvertColorsEnabled() ? @"dark" : @"light";
    }

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
    else
    {
        // Set light theme colors by default.
        theme = DefaultTheme.shared;
    }

    return theme;
}

@end
