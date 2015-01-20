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

#import <UIKit/UIKit.h>
#import <AddressBook/AddressBook.h>

@interface ConsoleContact : NSObject

// display name
@property (nonatomic, copy, readwrite) NSString *displayName;

@property (nonatomic, copy, readwrite) UIImage *thumbnail;

// array of ConsolePhoneNumber
@property (nonatomic, readwrite) NSArray *phoneNumbers;
// array of ConsoleEmail
@property (nonatomic, readwrite) NSArray *emailAddresses;
// array of strings
@property (nonatomic, readonly) NSArray* matrixIdentifiers;

- (id) initWithABRecord:(ABRecordRef)record;

@end