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

#import "RoomEncryptedDataBubbleCell.h"

NSString *const kRoomEncryptedDataBubbleCellTapOnEncryptionIcon = @"kRoomEncryptedDataBubbleCellTapOnEncryptionIcon";

@implementation RoomEncryptedDataBubbleCell

+ (UIImage*)encryptionIconForEvent:(MXEvent*)event andSession:(MXSession*)session
{
    NSString *encryptionIcon;
    
    if (!event.isEncrypted)
    {
        // Patch: Display the verified icon on outgoing messages in the encrypted rooms (until #773 is fixed)
        MXRoom *room = [session roomWithRoomId:event.roomId];
        if (room.state.isEncrypted && session.crypto && [event.sender isEqualToString:session.myUser.userId])
        {
            // The outgoing message are encrypted by default
            encryptionIcon = @"e2e_verified";
        }
        else
        {
            encryptionIcon = @"e2e_unencrypted";
        }
    }
    else if (event.decryptionError)
    {
        encryptionIcon = @"e2e_blocked";
    }
    else
    {
        MXRoom *room = [session roomWithRoomId:event.roomId];
        MXDeviceInfo *deviceInfo = [room eventDeviceInfo:event];
        
        if (deviceInfo)
        {
            switch (deviceInfo.verified)
            {
                case MXDeviceUnverified:
                {
                    encryptionIcon = @"e2e_warning";
                    break;
                }
                case MXDeviceVerified:
                {
                    encryptionIcon = @"e2e_verified";
                    break;
                }
                default:
                    break;
            }
        }
    }
    
    if (!encryptionIcon)
    {
        // Use the warning icon by default
        encryptionIcon = @"e2e_warning";
    }
    
    return [UIImage imageNamed:encryptionIcon];
}

@end