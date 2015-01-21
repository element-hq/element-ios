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

#import "ContactTableCell.h"

#import "MatrixHandler.h"

#import "MXTools.h"

@interface ContactTableCell() {
    id membersListener;
}
@end

@implementation ContactTableCell

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    if (membersListener) {
        [[MatrixHandler sharedHandler].mxSession removeListener:membersListener];
        membersListener = nil;
    }
}

- (void)setContact:(ConsoleContact *)aContact {
    MatrixHandler *mxHandler = [MatrixHandler sharedHandler];
    
    _contact = aContact;

    [_contact checkMatrixIdentifiers];
    self.matrixUserIconView.hidden = (0 == aContact.matrixIdentifiers.count);
    
    // remove any pending observers
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    // remove the matrix info until they are retrieved from the Matrix SDK
    if (membersListener) {
        [mxHandler.mxSession removeListener:membersListener];
        membersListener = nil;
    }
    self.thumbnailView.layer.borderWidth = 0;
    
    // be warned when the matrix ID and the thumbnail is updated
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onMatrixIdUpdate:)  name:kConsoleContactMatrixIdentifierUpdateNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onThumbnailUpdate:) name:kConsoleContactThumbnailUpdateNotification object:nil];
    
    // Register a listener for events that concern room members
    NSArray *mxMembersEvents = @[
                                    kMXEventTypeStringPresence
                                ];
    membersListener = [mxHandler.mxSession listenToEventsOfTypes:mxMembersEvents onEvent:^(MXEvent *event, MXEventDirection direction, id customObject) {
        // consider only live event
        if (direction == MXEventDirectionForwards) {
            NSString* matrixUserID = nil;
            
            // get the matrix identifiers
            NSArray* matrixIdentifiers = self.contact.matrixIdentifiers;
            
            if (matrixIdentifiers.count > 0) {
                matrixUserID = [self.contact.matrixIdentifiers objectAtIndex:0];
            }
            
            // the event is the current user event
            if (matrixUserID && [matrixUserID isEqualToString:event.userId]) {
                [self refreshPresenceUserRing:[MXTools presence:event.content[@"presence"]]];
            }
        }
    }];
    
    // init the contact info
    self.contactDisplayNameLabel.text = _contact.displayName;
    [self refreshContactThumbnail];
    [self manageMatrixIcon];
}

- (void)refreshUserPresence {
    // search the linked mxUser
    MatrixHandler *mxHandler = [MatrixHandler sharedHandler];
    
    // get the matrix identifiers
    NSArray* matrixIdentifiers = self.contact.matrixIdentifiers;
    
    // if defined
    if (matrixIdentifiers.count > 0) {
        // get the first matrix identifier
        NSString* matrixUserID = [self.contact.matrixIdentifiers objectAtIndex:0];
        
        // check if already known as a Matrix user
        MXUser* mxUser = [mxHandler.mxSession userWithUserId:matrixUserID];
        
        // check if the mxUser is known
        // if it is not known, the presence cannot be retrieved
        if (mxUser) {
            [self refreshPresenceUserRing:mxUser.presence];
            // we know that this user is a matrix one
            self.matrixUserIconView.hidden = NO;
        }
    }
}

- (void)refreshContactThumbnail {
    self.thumbnailView.image = [self.contact thumbnailWithPreferedSize:self.thumbnailView.frame.size];
    
    if (!self.thumbnailView.image) {
        self.thumbnailView.image = [UIImage imageNamed:@"default-profile"];
    }
    
    // display the thumbnail in a circle
    if (self.thumbnailView.layer.cornerRadius  != self.thumbnailView.frame.size.width / 2) {
        self.thumbnailView.layer.cornerRadius = self.thumbnailView.frame.size.width / 2;
        self.thumbnailView.clipsToBounds = YES;
    }
}

- (void)refreshPresenceUserRing:(MXPresence)presenceStatus {
    UIColor* ringColor = [[MatrixHandler sharedHandler] getPresenceRingColor:presenceStatus];
    
    // if the thumbnail is defined
    if (ringColor) {
        self.thumbnailView.layer.borderWidth = 2;
        self.thumbnailView.layer.borderColor = ringColor.CGColor;
    } else {
        // remove the border
        // else it draws black border
        self.thumbnailView.layer.borderWidth = 0;
    }
}

- (void)manageMatrixIcon {
    self.matrixUserIconView.hidden = (0 == _contact.matrixIdentifiers.count);
    
    // try to update the thumbnail with the matrix thumbnail
    if (_contact.matrixIdentifiers) {
        [self refreshContactThumbnail];
    }
    
    [self refreshUserPresence];
}

- (void)onMatrixIdUpdate:(NSNotification *)notif {
    // sanity check
    if ([notif.object isKindOfClass:[NSString class]]) {
        NSString* matrixID = notif.object;
        
        if ([matrixID isEqualToString:self.contact.contactID]) {
            [self manageMatrixIcon];
        }
    }
}

- (void)onThumbnailUpdate:(NSNotification *)notif {
    // sanity check
    if ([notif.object isKindOfClass:[NSString class]]) {
        NSString* matrixID = notif.object;
        
        if ([matrixID isEqualToString:self.contact.contactID]) {
            [self refreshContactThumbnail];
            self.matrixUserIconView.hidden = (0 == _contact.matrixIdentifiers.count);
        }
    }
}

@end