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

- (void)render:(MXKRecentCellData *)cellData
{
    
    //NSString *imageUrl = [self.matrixRestClient urlOfContentThumbnail:cellData toFitViewSize:mxkImageView.frame.size withMethod:MXThumbnailingMethodCrop];
    //[self.avatarImageView setImageURL:nil withType:nil andImageOrientation:UIImageOrientationUp previewImage:nil];
    
    self.roomTitleLabel.text = cellData.roomDisplayname;
    
    self.directRoomBorderView.hidden = !cellData.roomSummary.isDirect;
    
    self.encryptedRoomIcon.hidden = !cellData.roomSummary.isEncrypted;
    
}

+ (CGFloat)cellHeight
{
    return 74;
}

/*- (void)render:(MXRoom *)room
{
    [room setRoomAvatarImageIn:self.avatarImageView];
    
    self.titleLabel.text = room.riotDisplayname;
    
    self.directRoomBorderView.hidden = !room.isDirect;
    
    self.encryptedRoomIcon.hidden = !room.state.isEncrypted;
}*/

@end
