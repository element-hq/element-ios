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

@implementation ContactTableCell

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)setContact:(ConsoleContact *)aContact {
    _contact = aContact;
    
    [_contact checkMatrixIdentifiers];
    self.matrixUserIconView.hidden = (0 == aContact.matrixIdentifiers.count);
    
    // remove any pending observers
    [[NSNotificationCenter defaultCenter] removeObserver:self];
     [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onMatrixIdUpdate:) name:kConsoleContactMatrixIdentifierUpdateNotification object:nil];
}

- (void)onMatrixIdUpdate:(NSNotification *)notif {
    // sanity check
    if ([notif.object isKindOfClass:[NSString class]]) {
        NSString* matrixID = notif.object;
        
        if ([matrixID isEqualToString:self.contact.contactID]) {
            self.matrixUserIconView.hidden = (0 == _contact.matrixIdentifiers.count);
        }
    }
}


@end