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

#import "GeneratedInterface-Swift.h"

@implementation Tools

+ (NSString *)presenceText:(MXUser *)user
{
    NSString* presenceText = [VectorL10n roomParticipantsUnknown];

    if (user)
    {
        switch (user.presence)
        {
            case MXPresenceOnline:
                presenceText = [VectorL10n roomParticipantsOnline];
                break;

            case MXPresenceUnavailable:
                presenceText = [VectorL10n roomParticipantsIdle];
                break;
                
            case MXPresenceUnknown: // Do like matrix-js-sdk
            case MXPresenceOffline:
                presenceText = [VectorL10n roomParticipantsOffline];
                break;
                
            default:
                break;
        }
        
        if (user.currentlyActive)
        {
            presenceText = [presenceText stringByAppendingString:[NSString stringWithFormat:@" %@",[VectorL10n roomParticipantsNow]]];
        }
        else if (-1 != user.lastActiveAgo && 0 < user.lastActiveAgo)
        {
            presenceText = [presenceText stringByAppendingString:[NSString stringWithFormat:@" %@ %@",
                                                                  [MXKTools formatSecondsIntervalFloored:(user.lastActiveAgo / 1000)],
                                                                  [VectorL10n roomParticipantsAgo]]];
        }
    }

    return presenceText;
}

#pragma mark - Universal link

+ (BOOL)isUniversalLink:(NSURL*)url
{
    BOOL isUniversalLink = NO;
    
    for (NSString *matrixPermalinkHost in BuildSettings.permalinkSupportedHosts)
    {
        if ([url.host isEqualToString:matrixPermalinkHost])
        {
            NSArray<NSString*> *hostPaths = BuildSettings.permalinkSupportedHosts[matrixPermalinkHost];
            if (hostPaths.count)
            {
                // iOS Patch: fix urls before using it
                NSURL *fixedURL = [Tools fixURLWithSeveralHashKeys:url];
                
                if (NSNotFound != [hostPaths indexOfObject:fixedURL.path])
                {
                    isUniversalLink = YES;
                    break;
                }
            }
            else
            {
                isUniversalLink = YES;
                break;
            }
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

@end
