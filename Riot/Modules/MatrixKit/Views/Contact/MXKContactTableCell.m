/*
Copyright 2024 New Vector Ltd.
Copyright 2017 Vector Creations Ltd
Copyright 2015 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "MXKContactTableCell.h"

@import MatrixSDK.MXTools;

#import "MXKContactManager.h"
#import "MXKAppSettings.h"

#import "NSBundle+MatrixKit.h"

#pragma mark - Constant definitions
NSString *const kMXKContactCellTapOnThumbnailView = @"kMXKContactCellTapOnThumbnailView";

NSString *const kMXKContactCellContactIdKey = @"kMXKContactCellContactIdKey";

@interface MXKContactTableCell()
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

@implementation MXKContactTableCell
@synthesize delegate;

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    self.thumbnailDisplayBoxType = MXKTableViewCellDisplayBoxTypeDefault;
    
    // No accessory view by default
    self.contactAccessoryViewType = MXKContactTableCellAccessoryCustom;
    
    self.hideMatrixPresence = NO;
}

- (void)customizeTableViewCellRendering
{
    [super customizeTableViewCellRendering];
    
    self.thumbnailView.defaultBackgroundColor = [UIColor clearColor];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    if (self.thumbnailDisplayBoxType == MXKTableViewCellDisplayBoxTypeCircle)
    {
        // Round image view for thumbnail
        self.thumbnailView.layer.cornerRadius = self.thumbnailView.frame.size.width / 2;
        self.thumbnailView.clipsToBounds = YES;
    }
    else if (self.thumbnailDisplayBoxType == MXKTableViewCellDisplayBoxTypeRoundedCorner)
    {
        self.thumbnailView.layer.cornerRadius = 5;
        self.thumbnailView.clipsToBounds = YES;
    }
    else
    {
        self.thumbnailView.layer.cornerRadius = 0;
        self.thumbnailView.clipsToBounds = NO;
    }
}

- (UIImage*)picturePlaceholder
{
    return [NSBundle mxk_imageFromMXKAssetsBundleWithName:@"default-profile"];
}

- (void)setContactAccessoryViewType:(MXKContactTableCellAccessoryType)contactAccessoryViewType
{
    _contactAccessoryViewType = contactAccessoryViewType;
    
    if (contactAccessoryViewType == MXKContactTableCellAccessoryMatrixIcon)
    {
        // Load default matrix icon
        self.contactAccessoryImageView.image = [NSBundle mxk_imageFromMXKAssetsBundleWithName:@"matrixUser"];
        self.contactAccessoryImageView.hidden = NO;
        self.contactAccessoryButton.hidden = YES;
        
        // Update accessory view visibility
        [self refreshMatrixIdentifiers];
    }
    else
    {
        // Hide accessory view by default
        self.contactAccessoryView.hidden = YES;
        self.contactAccessoryImageView.hidden = YES;
        self.contactAccessoryButton.hidden = YES;
    }
}

#pragma mark - MXKCellRendering

- (void)render:(MXKCellData *)cellData
{
    // Sanity check: accept only object of MXKContact classes or sub-classes
    NSParameterAssert([cellData isKindOfClass:[MXKContact class]]);
    
    contact = (MXKContact*)cellData;
    
    // remove any pending observers
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    if (mxPresenceObserver)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:mxPresenceObserver];
        mxPresenceObserver = nil;
    }
    
    self.thumbnailView.layer.borderWidth = 0;
    
    if (contact)
    {
        // Be warned when the thumbnail is updated
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onThumbnailUpdate:) name:kMXKContactThumbnailUpdateNotification object:nil];
        
        if (! self.hideMatrixPresence)
        {
            // Observe contact presence change
            MXWeakify(self);
            mxPresenceObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kMXKContactManagerMatrixUserPresenceChangeNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {
                MXStrongifyAndReturnIfNil(self);

                // get the matrix identifiers
                NSArray* matrixIdentifiers = self->contact.matrixIdentifiers;
                if (matrixIdentifiers.count > 0)
                {
                    // Consider only the first id
                    NSString *matrixUserID = matrixIdentifiers.firstObject;
                    if ([matrixUserID isEqualToString:notif.object])
                    {
                        [self refreshPresenceUserRing:[MXTools presence:[notif.userInfo objectForKey:kMXKContactManagerMatrixPresenceKey]]];
                    }
                }
            }];
        }
        
        if (!contact.isMatrixContact)
        {
            // Be warned when the linked matrix IDs are updated
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onMatrixIdUpdate:)  name:kMXKContactManagerDidUpdateLocalContactMatrixIDsNotification object:nil];
        }
        
        NSArray* matrixIDs = contact.matrixIdentifiers;
        
        if (matrixIDs.count)
        {
            self.contactDisplayNameLabel.hidden = YES;
            
            self.matrixDisplayNameLabel.hidden = NO;
            self.matrixDisplayNameLabel.text = contact.displayName;
            self.matrixIDLabel.hidden = NO;
            self.matrixIDLabel.text = [matrixIDs firstObject];
        }
        else
        {
            self.contactDisplayNameLabel.hidden = NO;
            self.contactDisplayNameLabel.text = contact.displayName;
            
            self.matrixDisplayNameLabel.hidden = YES;
            self.matrixIDLabel.hidden = YES;
        }
        
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onContactThumbnailTap:)];
        [tap setNumberOfTouchesRequired:1];
        [tap setNumberOfTapsRequired:1];
        [tap setDelegate:self];
        [self.thumbnailView addGestureRecognizer:tap];
    }
    
    [self refreshContactThumbnail];
    [self manageMatrixIcon];
}

+ (CGFloat)heightForCellData:(MXKCellData*)cellData withMaximumWidth:(CGFloat)maxWidth
{
    // The height is fixed
    return 50;
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

#pragma mark -

- (void)refreshMatrixIdentifiers
{
    // Look for a potential matrix user linked with this contact
    NSArray* matrixIdentifiers = contact.matrixIdentifiers;
    
    if ((matrixIdentifiers.count > 0) && (! self.hideMatrixPresence))
    {
        // Consider only the first matrix identifier
        NSString* matrixUserID = matrixIdentifiers.firstObject;
        
        // Consider here all sessions reported into contact manager
        NSArray* mxSessions = [MXKContactManager sharedManager].mxSessions;
        for (MXSession *mxSession in mxSessions)
        {
            MXUser *mxUser = [mxSession userWithUserId:matrixUserID];
            if (mxUser)
            {
                [self refreshPresenceUserRing:mxUser.presence];
                break;
            }
        }
    }
    
    // Update accessory view visibility
    if (self.contactAccessoryViewType == MXKContactTableCellAccessoryMatrixIcon)
    {
        self.contactAccessoryView.hidden = (!matrixIdentifiers.count);
    }
}

- (void)refreshContactThumbnail
{
    self.thumbnailView.image = [contact thumbnailWithPreferedSize:self.thumbnailView.frame.size];
    
    if (!self.thumbnailView.image)
    {
        self.thumbnailView.image = self.picturePlaceholder;
    }
}

- (void)refreshPresenceUserRing:(MXPresence)presenceStatus
{
    UIColor* ringColor;
    
    switch (presenceStatus)
    {
        case MXPresenceOnline:
            ringColor = [[MXKAppSettings standardAppSettings] presenceColorForOnlineUser];
            break;
        case MXPresenceUnavailable:
            ringColor = [[MXKAppSettings standardAppSettings] presenceColorForUnavailableUser];
            break;
        case MXPresenceOffline:
            ringColor = [[MXKAppSettings standardAppSettings] presenceColorForOfflineUser];
            break;
        default:
            ringColor = nil;
    }
    
    // if the thumbnail is defined
    if (ringColor && (! self.hideMatrixPresence))
    {
        self.thumbnailView.layer.borderWidth = 2;
        self.thumbnailView.layer.borderColor = ringColor.CGColor;
    }
    else
    {
        // remove the border
        // else it draws black border
        self.thumbnailView.layer.borderWidth = 0;
    }
}

- (void)manageMatrixIcon
{
    // try to update the thumbnail with the matrix thumbnail
    if (contact.matrixIdentifiers)
    {
        [self refreshContactThumbnail];
    }
    
    [self refreshMatrixIdentifiers];
}

- (void)onMatrixIdUpdate:(NSNotification *)notif
{
    // sanity check
    if ([notif.object isKindOfClass:[NSString class]])
    {
        NSString* contactID = notif.object;
        
        if ([contactID isEqualToString:contact.contactID])
        {
            [self manageMatrixIcon];
        }
    }
}

- (void)onThumbnailUpdate:(NSNotification *)notif
{
    // sanity check
    if ([notif.object isKindOfClass:[NSString class]])
    {
        NSString* contactID = notif.object;
        
        if ([contactID isEqualToString:contact.contactID])
        {
            [self refreshContactThumbnail];
            
            [self refreshMatrixIdentifiers];
        }
    }
}

#pragma mark - Action

- (IBAction)onContactThumbnailTap:(id)sender
{
    if (self.delegate)
    {
        [self.delegate cell:self didRecognizeAction:kMXKContactCellTapOnThumbnailView userInfo:@{kMXKContactCellContactIdKey: contact.contactID}];
    }
}

@end
