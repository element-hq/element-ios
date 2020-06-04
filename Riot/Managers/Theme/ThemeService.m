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

@interface ThemeService()

/// Evaluated theme identifier from themeId.
@property (nonatomic, copy) NSString *evaluatedThemeId;

@end

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

- (void)setEvaluatedThemeId:(NSString *)evaluatedThemeId
{
    if (![_evaluatedThemeId isEqualToString:evaluatedThemeId])
    {
        _evaluatedThemeId = evaluatedThemeId;
        self.theme = [self themeWithEvaluatedThemeId:self.evaluatedThemeId];
    }
}

- (void)setTheme:(id<Theme> _Nonnull)theme
{
    _theme = theme;
    
    [self updateAppearance];

    [[NSNotificationCenter defaultCenter] postNotificationName:kThemeServiceDidChangeThemeNotification object:nil];
}

/// Eliminated themeId into 3 values: "dark", "black" or "light"
/// @param themeId Theme identifier setting value. Can be "auto" to respect system settings.
- (NSString *)evaluateThemeIdFromThemeId:(NSString *)themeId
{
    NSString *resultThemeId = themeId;
    
    if ([themeId isEqualToString:@"auto"])
    {
        if (@available(iOS 13, *))
        {
            // Translate "auto" into a theme with UITraitCollection
            resultThemeId = ([UITraitCollection currentTraitCollection].userInterfaceStyle == UIUserInterfaceStyleDark) ? @"dark" : @"light";
        }
        else
        {
            // Translate "auto" into a theme
            resultThemeId = UIAccessibilityIsInvertColorsEnabled() ? @"dark" : @"light";
        }
    }
    else if (![themeId isEqualToString:@"dark"] && ![themeId isEqualToString:@"black"])
    {
        // Use light theme by default
        resultThemeId = @"light";
    }
    
    return resultThemeId;
}

/// Gets the theme from evaluated theme id ("dark", "black" or "light")
/// @param themeId Evaluated theme id. Do not pass "auto" for this parameter
- (id<Theme>)themeWithEvaluatedThemeId:(NSString*)themeId
{
    if ([themeId isEqualToString:@"dark"])
    {
        return [DarkTheme new];
    }
    else if ([themeId isEqualToString:@"black"])
    {
        return [BlackTheme new];
    }
    else
    {
        //  "light" or something else
        return [DefaultTheme new];
    }
}

#pragma mark - Private methods

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        // Riot Colors not yet themeable
        _riotColorBlue = [[UIColor alloc] initWithRgb:0x81BDDB];
        _riotColorCuriousBlue = [[UIColor alloc] initWithRgb:0x2A9EDB];
        _riotColorIndigo = [[UIColor alloc] initWithRgb:0xBD79CC];
        _riotColorOrange = [[UIColor alloc] initWithRgb:0xF8A15F];

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
    }
    return self;
}

- (void)reEvaluateTheme
{
     self.evaluatedThemeId = [self evaluateThemeIdFromThemeId:self.themeId];
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
    
    // Define the navigation bar text color
    [[UINavigationBar appearance] setTintColor:self.theme.tintColor];
    
    // Define the UISearchBar cancel button color
    [[UIBarButtonItem appearanceWhenContainedInInstancesOfClasses:@[[UISearchBar class]]] setTitleTextAttributes:@{ NSForegroundColorAttributeName : self.theme.tintColor }                                                                                                        forState: UIControlStateNormal];
}

@end
