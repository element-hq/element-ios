/*
 Copyright 2014 OpenMarket Ltd
 
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

#import <MatrixKit/MatrixKit.h>

#import "ContactTableCell.h"

#import "MXTools.h"

#import "ContactManager.h"

@interface ContactTableCell()
{
    id mxPresenceObserver;
}
@end

@implementation ContactTableCell

- (void)dealloc
{
}

- (void)setContact:(MXCContact *)contact
{
    _contact = contact;
    
    // remove any pending observers
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    if (mxPresenceObserver) {
        [[NSNotificationCenter defaultCenter] removeObserver:mxPresenceObserver];
        mxPresenceObserver = nil;
    }
    
    self.thumbnailView.layer.borderWidth = 0;
    
    if (contact) {
        // be warned when the matrix ID and the thumbnail is updated
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onMatrixIdUpdate:)  name:kMXCContactMatrixIdentifierUpdateNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onThumbnailUpdate:) name:kMXCContactThumbnailUpdateNotification object:nil];
        
        mxPresenceObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kContactManagerMatrixUserPresenceChangeNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {
            
            // get the matrix identifiers
            NSArray* matrixIdentifiers = self.contact.matrixIdentifiers;
            if (matrixIdentifiers.count > 0)
            {
                // Consider only the first id
                NSString *matrixUserID = matrixIdentifiers.firstObject;
                if ([matrixUserID isEqualToString:notif.object])
                {
                    [self refreshPresenceUserRing:[MXTools presence:[notif.userInfo objectForKey:kContactManagerMatrixPresenceKey]]];
                }
            }
        }];
        
        // Refresh matrix info of the contact
        [[ContactManager sharedManager] updateMatrixIDsForContact:_contact];
        
        NSArray* matrixIDs = _contact.matrixIdentifiers;
        
        if (matrixIDs.count == 1)
        {
            self.contactDisplayNameLabel.hidden = YES;
            
            self.matrixDisplayNameLabel.hidden = NO;
            self.matrixDisplayNameLabel.text = _contact.displayName;
            self.matrixIDLabel.hidden = NO;
            self.matrixIDLabel.text = [ _contact.matrixIdentifiers objectAtIndex:0];
        }
        else
        {
            self.contactDisplayNameLabel.hidden = NO;
            self.contactDisplayNameLabel.text = _contact.displayName;
            
            self.matrixDisplayNameLabel.hidden = YES;
            self.matrixIDLabel.hidden = YES;
        }
    }
    
    [self refreshContactThumbnail];
    [self manageMatrixIcon];
}

- (void)refreshUserPresence
{
    // Look for a potential matrix user linked with this contact
    NSArray* matrixIdentifiers = self.contact.matrixIdentifiers;
    if (matrixIdentifiers.count > 0)
    {
        // Consider only the first matrix identifier
        NSString* matrixUserID = matrixIdentifiers.firstObject;
        
        // Consider here all sessions reported into contact manager
        NSArray* mxSessions = [ContactManager sharedManager].mxSessions;
        for (MXSession *mxSession in mxSessions)
        {
            MXUser *mxUser = [mxSession userWithUserId:matrixUserID];
            if (mxUser)
            {
                [self refreshPresenceUserRing:mxUser.presence];
                break;
            }
        }
        
        // we know that this user is a matrix one
        self.matrixUserIconView.hidden = NO;
    }
}

- (void)refreshContactThumbnail
{
    self.thumbnailView.image = [self.contact thumbnailWithPreferedSize:self.thumbnailView.frame.size];
    
    if (!self.thumbnailView.image)
    {
        self.thumbnailView.image = [UIImage imageNamed:@"default-profile"];
    }
    
    // display the thumbnail in a circle
    if (self.thumbnailView.layer.cornerRadius  != self.thumbnailView.frame.size.width / 2)
    {
        self.thumbnailView.layer.cornerRadius = self.thumbnailView.frame.size.width / 2;
        self.thumbnailView.clipsToBounds = YES;
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
    if (ringColor)
        
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
    self.matrixUserIconView.hidden = (0 == _contact.matrixIdentifiers.count);
    
    // try to update the thumbnail with the matrix thumbnail
    if (_contact.matrixIdentifiers)
    {
        [self refreshContactThumbnail];
    }
    
    [self refreshUserPresence];
}

- (void)onMatrixIdUpdate:(NSNotification *)notif
{
    // sanity check
    if ([notif.object isKindOfClass:[NSString class]])
    {
        NSString* matrixID = notif.object;
        
        if ([matrixID isEqualToString:self.contact.contactID])
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
        NSString* matrixID = notif.object;
        
        if ([matrixID isEqualToString:self.contact.contactID])
        {
            [self refreshContactThumbnail];
            self.matrixUserIconView.hidden = (0 == _contact.matrixIdentifiers.count);
            
            [self refreshUserPresence];
        }
    }
}

@end