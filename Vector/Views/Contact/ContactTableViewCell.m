/*
 Copyright 2015 OpenMarket Ltd
 
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

#import "ContactTableViewCell.h"

#import "MXKContactManager.h"

#import "VectorDesignValues.h"

#import "AvatarGenerator.h"

@interface ContactTableViewCell()
{
    /**
     The current displayed contact.
     */
    MXKContact *contact;
    
    /**
     The observer of the presence for matrix user.
     */
    id mxPresenceObserver;
}
@end

@implementation ContactTableViewCell
@synthesize mxRoom, mxSession;

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    self.thumbnailView.layer.cornerRadius = self.thumbnailView.frame.size.width / 2;
    self.thumbnailView.clipsToBounds = YES;
    
    // apply the vector colours
    self.bottomLineSeparator.backgroundColor = VECTOR_SILVER_COLOR;
    self.topLineSeparator.backgroundColor = VECTOR_SILVER_COLOR;
    self.lastPresenceLabel.textColor = VECTOR_TEXT_GRAY_COLOR;
}

- (void)setShowCustomAccessoryView:(BOOL)show
{
    _showCustomAccessoryView = show;
    
    if (show)
    {
        self.customAccessViewWidthConstraint.constant = 25;
        self.customAccessoryViewLeadingConstraint.constant = 13;
    }
    else
    {
        self.customAccessViewWidthConstraint.constant = 0;
        self.customAccessoryViewLeadingConstraint.constant = 0;
    }
}

#pragma mark - MXKCellRendering

// returns the first matrix id of the contact
// nil if there is none
- (NSString*)getFirstMatrixId
{
    NSString* matrixId = nil;
    
    if (contact.matrixIdentifiers.count > 0)
    {
        matrixId = contact.matrixIdentifiers.firstObject;
    }
    
    return matrixId;
}

- (void)render:(MXKCellData *)cellData
{
    // remove any pending observers
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    if (mxPresenceObserver)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:mxPresenceObserver];
        mxPresenceObserver = nil;
    }
    
    
    // Sanity check: accept only object of MXKContact classes or sub-classes
    NSParameterAssert([cellData isKindOfClass:[MXKContact class]]);
    
    contact = (MXKContact*)cellData;
    
    // sanity check
    // should never happen
    if (!contact)
    {
        self.thumbnailView.image = nil;
        self.contactDisplayNameLabel.text = nil;
        self.lastPresenceLabel.text = nil;
        
        return;
    }
    
    // Be warned when the thumbnail is updated
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onThumbnailUpdate:) name:kMXKContactThumbnailUpdateNotification object:nil];
    
    // Observe contact presence change
    mxPresenceObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kMXKContactManagerMatrixUserPresenceChangeNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {
        
        NSString* matrixId = [self getFirstMatrixId];
        
        if (matrixId && [matrixId isEqualToString:notif.object])
        {
            [self refreshContactPresence];
        }
    }];
    
    if (!contact.isMatrixContact)
    {
        // Refresh matrix info of the contact
        [[MXKContactManager sharedManager] updateMatrixIDsForLocalContact:contact];
    }
    
    [self refreshContactDisplayName];
    [self refreshContactPresence];
    [self refreshContactThumbnail];
}

+ (CGFloat)heightForCellData:(MXKCellData*)cellData withMaximumWidth:(CGFloat)maxWidth
{
    return 74;
}

- (void)didEndDisplay
{
    // remove any pending observers
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    if (mxPresenceObserver) {
        [[NSNotificationCenter defaultCenter] removeObserver:mxPresenceObserver];
        mxPresenceObserver = nil;
    }
    
    // Remove all gesture recognizer
    while (self.thumbnailView.gestureRecognizers.count)
    {
        [self.thumbnailView removeGestureRecognizer:self.thumbnailView.gestureRecognizers[0]];
    }
    
    self.delegate = nil;
    contact = nil;
}

#pragma mark Refresh cell part

- (void)refreshContactThumbnail
{
    UIImage* image = [contact thumbnailWithPreferedSize:self.thumbnailView.frame.size];
    
    if (!image)
    {
        NSString* matrixId = [self getFirstMatrixId];
        
        if (matrixId)
        {
            image = [AvatarGenerator generateRoomMemberAvatar:matrixId displayName:contact.displayName];
        }
        else
        {
            image = [AvatarGenerator generateAvatarForText:contact.displayName];
        }
    }
    
    self.thumbnailView.image = image;
}

- (void)refreshContactDisplayName
{
    self.contactDisplayNameLabel.text = contact.displayName;
}

- (void)refreshContactPresence
{
    NSString* presenceText = nil;
    NSString* matrixId = [self getFirstMatrixId];
    MXRoomMember* member = [self.mxRoom.state memberWithUserId:matrixId];

    // the oneself user is always active
    if ([matrixId isEqualToString:self.mxSession.myUser.userId])
    {
        presenceText = NSLocalizedStringFromTable(@"room_participants_active", @"Vector", nil);
    }
    else if (!member || (member.membership != MXMembershipJoin))
    {
        if (member.membership == MXMembershipInvite)
        {
            presenceText =  NSLocalizedStringFromTable(@"room_participants_invite", @"Vector", nil);
        }
        else if (member.membership == MXMembershipLeave)
        {
            presenceText =  NSLocalizedStringFromTable(@"room_participants_leave", @"Vector", nil);
        }
        else if (member.membership == MXMembershipBan)
        {
            presenceText =  NSLocalizedStringFromTable(@"room_participants_ban", @"Vector", nil);
        }
    }
    else
    {
        MXUser *user = [self.mxSession userWithUserId:matrixId];
        
        if (user)
        {
            if (user.presence == MXPresenceOnline)
            {
                presenceText  = NSLocalizedStringFromTable(@"room_participants_active", @"Vector", nil);
            }
            else
            {
                NSUInteger lastActiveMs = user.lastActiveAgo;
                
                if (-1 != lastActiveMs)
                {
                    NSUInteger lastActivehour = lastActiveMs / 1000 / 60 / 60;
                    NSUInteger lastActiveDays = lastActivehour / 24;
                    
                    if (lastActivehour < 1)
                    {
                        presenceText = NSLocalizedStringFromTable(@"room_participants_active_less_1_hour", @"Vector", nil);
                    }
                    else if (lastActivehour < 24)
                    {
                        presenceText = [NSString stringWithFormat:NSLocalizedStringFromTable(@"room_participants_active_less_x_hours", @"Vector", nil), lastActivehour];
                    }
                    else
                    {
                        presenceText = [NSString stringWithFormat:NSLocalizedStringFromTable(@"room_participants_active_less_x_days", @"Vector", nil), lastActiveDays];
                    }
                }
            }
        }
    }

    self.lastPresenceLabel.text = presenceText;
}

#pragma mark - events

- (void)onThumbnailUpdate:(NSNotification *)notif
{
    // sanity check
    if ([notif.object isKindOfClass:[NSString class]])
    {
        NSString* contactID = notif.object;
        
        if ([contactID isEqualToString:contact.contactID])
        {
            [self refreshContactThumbnail];
        }
    }
}

@end