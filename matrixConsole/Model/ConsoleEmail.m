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

#import "ConsoleEmail.h"
#import "MatrixHandler.h"

#import "ConsoleContact.h"

#import "MediaManager.h"

@interface ConsoleEmail()
@end

@implementation ConsoleEmail

- (void) commonInit {
    // init members
    _emailAddress = nil;
    _type = nil;
}

- (id)init {
    self = [super init];
    
    if (self) {
        [self commonInit];
    }
    
    return self;
}

- (id)initWithEmailAddress:(NSString*)anEmailAddress type:(NSString*)aType contactID:(NSString*)aContactID matrixID:(NSString*)matrixID {
    self = [super initWithContactID:aContactID matrixID:matrixID];
    
    if (self) {
        [self commonInit];
        _emailAddress = anEmailAddress;
        _type = aType;
    }
    
    return self;
}

@end
