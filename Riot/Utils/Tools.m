/*
 Copyright 2016 OpenMarket Ltd

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

#import "Tools.h"

@implementation Tools

+ (NSString *)presenceText:(MXUser *)user
{
    NSString* presenceText = NSLocalizedStringFromTable(@"room_participants_unknown", @"Vector", nil);

    if (user)
    {
        switch (user.presence)
        {
            case MXPresenceOnline:
                presenceText = NSLocalizedStringFromTable(@"room_participants_online", @"Vector", nil);
                break;

            case MXPresenceUnavailable:
                presenceText = NSLocalizedStringFromTable(@"room_participants_idle", @"Vector", nil);
                break;

            case MXPresenceUnknown: // Do like matrix-js-sdk
            case MXPresenceOffline:
                presenceText = NSLocalizedStringFromTable(@"room_participants_offline", @"Vector", nil);
                break;

            default:
                break;
        }

        if (user.currentlyActive)
        {
            presenceText = [presenceText stringByAppendingString:[NSString stringWithFormat:@" %@",
                                                                  NSLocalizedStringFromTable(@"room_participants_now", @"Vector", nil)]];
        }
        else if (-1 != user.lastActiveAgo && 0 < user.lastActiveAgo)
        {
            presenceText = [presenceText stringByAppendingString:[NSString stringWithFormat:@" %@ %@",
                                                                  [MXKTools formatSecondsIntervalFloored:(user.lastActiveAgo / 1000)],
                                                                  NSLocalizedStringFromTable(@"room_participants_ago", @"Vector", nil)]];
        }
    }

    return presenceText;
}

#pragma mark - Universal link

+ (NSString *)webAppUrl
{
    return [[NSUserDefaults standardUserDefaults] objectForKey:@"webAppUrl"];
    //return [[NSUserDefaults standardUserDefaults] objectForKey:@"webAppUrlBeta"];
    //return [[NSUserDefaults standardUserDefaults] objectForKey:@"webAppUrlDev"];
}

+ (BOOL)isUniversalLink:(NSURL*)url
{
    BOOL isUniversalLink = NO;

    if ([url.host isEqualToString:@"vector.im"] || [url.host isEqualToString:@"www.vector.im"]
        || [url.host isEqualToString:@"riot.im"] || [url.host isEqualToString:@"www.riot.im"])
    {
        // iOS Patch: fix vector.im/riot.im urls before using it
        NSURL *fixedURL = [Tools fixURLWithSeveralHashKeys:url];

        if (NSNotFound != [@[@"/app", @"/staging", @"/beta", @"/develop"] indexOfObject:fixedURL.path])
        {
            isUniversalLink = YES;
        }
    }
    else if ([url.host isEqualToString:@"matrix.to"] || [url.host isEqualToString:@"www.matrix.to"])
    {
        // iOS Patch: fix matrix.to urls before using it
        NSURL *fixedURL = [Tools fixURLWithSeveralHashKeys:url];

        if ([fixedURL.path isEqualToString:@"/"])
        {
            isUniversalLink = YES;
        }
    }

    return isUniversalLink;
}

+ (NSURL *)fixURLWithSeveralHashKeys:(NSURL *)url
{
    NSURL *fixedURL = url;

    // The NSURL may have no fragment because it contains more that '%23' occurence
    if (!url.fragment)
    {
        // Replacing the first '%23' occurence into a '#' makes NSURL works correctly
        NSString *urlString = url.absoluteString;
        NSRange range = [urlString rangeOfString:@"%23"];
        if (NSNotFound != range.location)
        {
            urlString = [urlString stringByReplacingCharactersInRange:range withString:@"#"];
            fixedURL = [NSURL URLWithString:urlString];
        }
    }

    return fixedURL;
}

#pragma mark - String utilities

+ (NSAttributedString *)setTextColorAlpha:(CGFloat)alpha inAttributedString:(NSAttributedString*)attributedString
{
    NSMutableAttributedString *string = [[NSMutableAttributedString alloc] initWithAttributedString:attributedString];

    // Check all attributes one by one
    [string enumerateAttributesInRange:NSMakeRange(0, attributedString.length) options:0 usingBlock:^(NSDictionary *attrs, NSRange range, BOOL *stop)
     {
         // Replace only colored texts
         if (attrs[NSForegroundColorAttributeName])
         {
             UIColor *color = attrs[NSForegroundColorAttributeName];
             color = [color colorWithAlphaComponent:0.2];

             NSMutableDictionary *newAttrs = [NSMutableDictionary dictionaryWithDictionary:attrs];
             newAttrs[NSForegroundColorAttributeName] = color;

             [string setAttributes:newAttrs range:range];
         }
     }];

    return string;
}

@end
