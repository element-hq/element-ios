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
    NSString* presenceText = NSLocalizedStringFromTable(@"room_participants_unkown", @"Vector", nil);

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
        else if (0 < user.lastActiveAgo)
        {
            presenceText = [presenceText stringByAppendingString:[NSString stringWithFormat:@" %@ %@",
                                                                  [MXKTools formatSecondsIntervalFloored:(user.lastActiveAgo / 1000)],
                                                                  NSLocalizedStringFromTable(@"room_participants_ago", @"Vector", nil)]];
        }
    }

    return presenceText;
}

@end
