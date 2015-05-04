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

#import <Foundation/Foundation.h>

#import <MatrixSDK/MatrixSDK.h>

#import "SectionedContacts.h"
#import "MXCContact.h"

// warn when there is a contacts list refresh
extern NSString *const kContactManagerContactsListRefreshNotification;

// the phonenumber has been internationalized
extern NSString *const kContactsDidInternationalizeNotification;

@interface ContactManager : NSObject {
    dispatch_queue_t processingQueue;
    NSMutableDictionary* matrixIDBy3PID;
}

+ (ContactManager*)sharedManager;

/**
 Associated matrix session (nil by default).
 This property is used to link matrix id to the contacts.
 */
@property (nonatomic) MXSession *mxSession;

/**
 Associated matrix REST Client (nil by default). Ignored if mxSession is defined.
 This property is used to make Matrix API requests when no matrix session is provided.
 */
@property (nonatomic) MXRestClient *mxRestClient;

@property (nonatomic, readonly) NSMutableArray *contacts;

// delete contacts info
- (void)reset;

// refresh the international phonenumber of the contacts
- (void)internationalizePhoneNumbers:(NSString*)countryCode;

// refresh self.contacts
- (void)fullRefresh;

// refresh matrix IDs
- (void)refreshContactMatrixIDs:(MXCContact*)contact;

// sort the contacts in sectioned arrays to be displayable in a UITableview
- (SectionedContacts *)getSectionedContacts:(NSArray*)contactsList;

@end
