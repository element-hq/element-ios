/*
 Copyright 2015 OpenMarket Ltd
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

#import "RoomIncomingTextMsgWithPaginationTitleBubbleCell.h"

#import "RiotDesignValues.h"
#import "Riot-Swift.h"

@implementation RoomIncomingTextMsgWithPaginationTitleBubbleCell

- (void)customizeTableViewCellRendering
{
    [super customizeTableViewCellRendering];
    
    self.userNameLabel.textColor = kRiotPrimaryTextColor;
    
    self.paginationLabel.textColor = RiotDesignValues.colorValues.accent;
    self.paginationSeparatorView.backgroundColor = RiotDesignValues.colorValues.accent;
    self.messageTextView.tintColor = RiotDesignValues.colorValues.accent;
}

- (void)render:(MXKCellData *)cellData
{
    [super render:cellData];
    
    if (bubbleData)
    {
        self.paginationLabel.text = [[bubbleData.eventFormatter dateStringFromDate:bubbleData.date withTime:NO] uppercaseString];
    }
}

@end
