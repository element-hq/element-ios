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

#import "MessagesSearchResultAttachmentBubbleCell.h"

#import "ThemeService.h"
#import "GeneratedInterface-Swift.h"
#import "MXKRoomBubbleTableViewCell+Riot.h"

@implementation MessagesSearchResultAttachmentBubbleCell

- (void)customizeTableViewCellRendering
{
    [super customizeTableViewCellRendering];
    
    self.roomNameLabel.textColor = ThemeService.shared.theme.textSecondaryColor;
    
    self.messageTextView.tintColor = ThemeService.shared.theme.tintColor;
    
    [self updateUserNameColor];
}

- (void)render:(MXKCellData *)cellData
{
    [super render:cellData];
    
    if (bubbleData)
    {
        MXRoom* room = [bubbleData.mxSession roomWithRoomId:bubbleData.roomId];
        if (room)
        {
            self.roomNameLabel.text = room.summary.displayname;
            if (!self.roomNameLabel.text.length)
            {
                self.roomNameLabel.text = [VectorL10n roomDisplaynameEmptyRoom];
            }
        }
        else
        {
            self.roomNameLabel.text = bubbleData.roomId;
        }
        
        [self updateUserNameColor];
    }
}

@end
