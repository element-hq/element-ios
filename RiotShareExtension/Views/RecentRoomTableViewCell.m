/*
 Copyright 2017 Aram Sargsyan
 
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

#import "RecentRoomTableViewCell.h"

#import "MXRoomSummary+Riot.h"

@interface RecentRoomTableViewCell ()

@property (weak, nonatomic) IBOutlet MXKImageView *avatarImageView;
@property (weak, nonatomic) IBOutlet UIView *directRoomBorderView;
@property (weak, nonatomic) IBOutlet UILabel *roomTitleLabel;
@property (weak, nonatomic) IBOutlet UIImageView *encryptedRoomIcon;

@end

@implementation RecentRoomTableViewCell

#pragma mark - MXKRecentTableViewCell

+ (UINib *)nib
{
    // Check whether a nib file is available
    NSBundle *mainBundle = [NSBundle bundleForClass:self.class];
    
    NSString *path = [mainBundle pathForResource:NSStringFromClass([self class]) ofType:@"nib"];
    if (path)
    {
        return [UINib nibWithNibName:NSStringFromClass([self class]) bundle:mainBundle];
    }
    return nil;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    // Round room avatars
    [self.avatarImageView.layer setCornerRadius:self.avatarImageView.frame.size.width / 2];
    self.avatarImageView.clipsToBounds = YES;
}

- (void)render:(MXKCellData *)cellData
{
    // Sanity check: accept only object of MXKRecentCellData classes or sub-classes
    NSParameterAssert([cellData isKindOfClass:[MXKRecentCellData class]]);
    
    roomCellData = (id<MXKRecentCellDataStoring>)cellData;
    if (roomCellData)
    {
        [roomCellData.roomSummary setRoomAvatarImageIn:self.avatarImageView];
        
        self.roomTitleLabel.text = roomCellData.roomSummary.displayname;
        if (!self.roomTitleLabel.text.length)
        {
            self.roomTitleLabel.text = NSLocalizedStringFromTable(@"room_displayname_no_title", @"Vector", nil);
        }  
        
        self.directRoomBorderView.hidden = !roomCellData.roomSummary.isDirect;
        
        self.encryptedRoomIcon.hidden = !roomCellData.roomSummary.isEncrypted;
    }
}

+ (CGFloat)cellHeight
{
    return 74;
}

@end
