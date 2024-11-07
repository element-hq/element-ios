/*
Copyright 2019-2024 New Vector Ltd.
Copyright 2017 Vector Creations Ltd
Copyright 2016 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "ThemeService.h"

#import "GeneratedInterface-Swift.h"

NSString *const kThemeServiceDidChangeThemeNotification = @"kThemeServiceDidChangeThemeNotification";

@implementation ThemeService
@synthesize themeId = _themeId;

+ (ThemeService *)shared
{
    static ThemeService *sharedOnceInstance;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedOnceInstance = [ThemeService new];
    });
    
    return sharedOnceInstance;
}

- (void)setThemeId:(NSString *)theThemeId
{
    _themeId = theThemeId;
    [self reEvaluateTheme];
}

- (void)setTheme:(id<Theme> _Nonnull)theme
{
    //  update only if really changed
    if (![_theme.identifier isEqualToString:theme.identifier])
    {
        _theme = theme;
        
        [self updateAppearance];

        [[NSNotificationCenter defaultCenter] postNotificationName:kThemeServiceDidChangeThemeNotification object:self];
    }
}

- (id<Theme>)themeWithThemeId:(NSString*)themeId
{
    id<Theme> theme;
    
    if (themeId == nil || [themeId isEqualToString:@"auto"])
    {
        if (@available(iOS 13, *))
        {
            // Translate "auto" into a theme with UITraitCollection
            themeId = ([UITraitCollection currentTraitCollection].userInterfaceStyle == UIUserInterfaceStyleDark) ? @"dark" : @"light";
        }
        else
        {
            // Translate "auto" into a theme
            themeId = UIAccessibilityIsInvertColorsEnabled() ? @"dark" : @"light";
        }
    }

    if ([themeId isEqualToString:@"dark"])
    {
        theme = [DarkTheme new];
    }
    else if ([themeId isEqualToString:@"black"])
    {
        theme = [BlackTheme new];
    }
    else
    {
        // Use light theme by default
        theme = [DefaultTheme new];
    }

    return theme;
}

- (BOOL)isCurrentThemeDark
{
    if ([self.theme.identifier isEqualToString:@"dark"] || [self.theme.identifier isEqualToString:@"black"])
    {
        return YES;
    }
    
    return NO;
}

#pragma mark - Private methods

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        // Riot Colors not yet themeable
        _riotColorCuriousBlue = [[UIColor alloc] initWithRgb:0x2A9EDB];        

        if (@available(iOS 13, *))
        {
            //  Observe application did become active for iOS appearance setting changes
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActive) name:UIApplicationDidBecomeActiveNotification object:nil];
        }
        else
        {
            // Observe "Invert Colours" settings changes (available since iOS 11)
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(accessibilityInvertColorsStatusDidChange) name:UIAccessibilityInvertColorsStatusDidChangeNotification object:nil];
        }
        
        [self reEvaluateTheme];
    }
    return self;
}

- (void)reEvaluateTheme
{
     self.theme = [self themeWithThemeId:self.themeId];
}

- (void)accessibilityInvertColorsStatusDidChange
{
    [self reEvaluateTheme];
}

- (void)applicationDidBecomeActive
{
    [self reEvaluateTheme];
}

- (void)updateAppearance
{
    [UIScrollView appearance].indicatorStyle = self.theme.scrollBarStyle;
    
    // Remove the extra height added to section headers in iOS 15
    if (@available(iOS 15.0, *))
    {
        UITableView.appearance.sectionHeaderTopPadding = 0;
    }
    
    // Define the navigation bar text color
    [[UINavigationBar appearance] setTintColor:self.theme.tintColor];
    
    // Define the UISearchBar cancel button color
    [[UIBarButtonItem appearanceWhenContainedInInstancesOfClasses:@[[UISearchBar class]]] setTitleTextAttributes:@{ NSForegroundColorAttributeName : self.theme.tintColor }                                                                                                        forState: UIControlStateNormal];
    
    [[UIStackView appearanceWhenContainedInInstancesOfClasses:@[[UINavigationBar class]]] setSpacing:-7];
    [[UIStackView appearanceWhenContainedInInstancesOfClasses:@[[UINavigationBar class]]] setDistribution:UIStackViewDistributionEqualCentering];
}

@end
