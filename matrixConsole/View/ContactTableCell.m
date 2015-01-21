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
    self.thumbnail.layer.borderWidth = 0;
    
    // add contact update info
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onMatrixIdUpdate:) name:kConsoleContactMatrixIdentifierUpdateNotification object:nil];
    
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
    
    [self refreshUserPresence];
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
        
        // unknown user
        if (!mxUser) {
            // request his presence
            [mxHandler.mxRestClient presence:matrixUserID
                                     success:^(MXPresenceResponse *presence) {
                                        [self refreshPresenceUserRing:presence.presenceStatus];
                                     }
                                     failure:^ (NSError *error) {
                                     }
             ];
            
        } else {
             [self refreshPresenceUserRing:mxUser.presence];
        }
    }
}

- (void)refreshPresenceUserRing:(MXPresence)presenceStatus {
    UIColor* ringColor = [[MatrixHandler sharedHandler] getPresenceRingColor:presenceStatus];
    
    // if the thumbnail is defined
    if (ringColor) {
        self.thumbnail.layer.borderWidth = 2;
        self.thumbnail.layer.borderColor = ringColor.CGColor;
    } else {
        // remove the border
        // else it draws black border
        self.thumbnail.layer.borderWidth = 0;
    }
}

- (void)onMatrixIdUpdate:(NSNotification *)notif {
    // sanity check
    if ([notif.object isKindOfClass:[NSString class]]) {
        NSString* matrixID = notif.object;
        
        if ([matrixID isEqualToString:self.contact.contactID]) {
            self.matrixUserIconView.hidden = (0 == _contact.matrixIdentifiers.count);
            
            // try to update the thumbnail with the matrix thumbnail
            if (_contact.matrixIdentifiers) {
                self.matrixUserIconView.image = self.contact.thumbnail;
            }
            
            [self refreshUserPresence];
        }
    }
}

- (void)onThumbnailUpdate:(NSNotification *)notif {
    // sanity check
    if ([notif.object isKindOfClass:[NSString class]]) {
        NSString* matrixID = notif.object;
        
        if ([matrixID isEqualToString:self.contact.contactID]) {
            self.thumbnail.image = self.contact.thumbnail;
        }
    }
}

@end