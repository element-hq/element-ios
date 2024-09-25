/*
Copyright 2024 New Vector Ltd.
Copyright 2017 Aram Sargsyan

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "RecentRoomTableViewCell.h"

#import "MXRoomSummary+Riot.h"
#import "ThemeService.h"

#import "GeneratedInterface-Swift.h"

@interface RecentRoomTableViewCell ()

@property (weak, nonatomic) IBOutlet MXKImageView *avatarImageView;
@property (weak, nonatomic) IBOutlet UILabel *roomTitleLabel;
@property (weak, nonatomic) IBOutlet UIImageView *encryptedRoomIcon;
@property (weak, nonatomic) IBOutlet UIButton *selectionButton;

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

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    self.roomTitleLabel.textColor = ThemeService.shared.theme.textPrimaryColor;
    self.contentView.backgroundColor = ThemeService.shared.theme.backgroundColor;
    self.selectionButton.tintColor = ThemeService.shared.theme.tintColor;
    
    [self.selectionButton setImage:AssetSharedImages.radioButtonDefault.image forState:UIControlStateNormal];
    [self.selectionButton setImage:AssetSharedImages.radioButtonSelected.image forState:UIControlStateSelected];
    
    [self.selectionButton setTitle:@"" forState:UIControlStateNormal];
    [self.selectionButton setTitle:@"" forState:UIControlStateSelected];
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
        [self.avatarImageView vc_setRoomAvatarImageWith:roomCellData.avatarUrl
                                                 roomId:roomCellData.roomIdentifier
                                            displayName:roomCellData.roomDisplayname
                                           mediaManager:roomCellData.roomSummary.mxSession.mediaManager];
        
        self.roomTitleLabel.text = roomCellData.roomDisplayname;
        if (!self.roomTitleLabel.text.length)
        {
            self.roomTitleLabel.text = [VectorL10n roomDisplaynameEmptyRoom];
        }  
        
        self.encryptedRoomIcon.hidden = YES;
    }
}

+ (CGFloat)cellHeight
{
    return 74;
}

- (void)setCustomSelected:(BOOL)selected animated:(BOOL)animated
{
    [UIView animateWithDuration:(animated ? 0.25f : 0.0f) animations:^{
        [self.selectionButton setSelected:selected];
    }];
}

@end
