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
#import "Tools.h"

#import "MXKContactManager.h"

@interface ContactTableViewCell()
{
    // The current displayed contact.
    MXKContact *contact;
    
    /**
     The observer of the presence for matrix user.
     */
    id mxPresenceObserver;
}
@end

@implementation ContactTableViewCell
@synthesize mxRoom;

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    // apply the vector colours
    self.lastPresenceLabel.textColor = kVectorTextColorGray;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    // Round image view
    self.thumbnailView.layer.cornerRadius = self.thumbnailView.frame.size.width / 2;
    self.thumbnailView.clipsToBounds = YES;
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
- (NSString*)firstMatrixId
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
    // Remove any pending observers
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    if (mxPresenceObserver)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:mxPresenceObserver];
        mxPresenceObserver = nil;
    }
    
    // Clear the default background color of a MXKImageView instance
    self.thumbnailView.backgroundColor = [UIColor clearColor];
    
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
        
        NSString* matrixId = self.firstMatrixId;
        
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
        NSString* matrixId = self.firstMatrixId;
        
        if (matrixId)
        {
            image = [AvatarGenerator generateAvatarForMatrixItem:matrixId withDisplayName:contact.displayName];
        }
        else if (contact.isThirdPartyInvite)
        {
            image = [AvatarGenerator generateAvatarForText:contact.displayName];
        }
        else
        {
            image = [AvatarGenerator imageFromText:@"@" withBackgroundColor:kVectorColorGreen];
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
    NSString* presenceText;
    NSString* matrixId = self.firstMatrixId;
    
    if (matrixId)
    {
        MXUser *user = nil;
        
        // Consider here all sessions reported into contact manager
        NSArray* mxSessions = [MXKContactManager sharedManager].mxSessions;
        for (MXSession *mxSession in mxSessions)
        {
            user = [mxSession userWithUserId:matrixId];
            if (user)
            {
                break;
            }
        }

        presenceText = [Tools presenceText:user];
    }
    else if (contact.isThirdPartyInvite)
    {
        presenceText =  NSLocalizedStringFromTable(@"room_participants_offline", @"Vector", nil);
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