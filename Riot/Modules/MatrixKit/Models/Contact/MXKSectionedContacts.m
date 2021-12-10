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

#import "MXKSectionedContacts.h"

@implementation MXKSectionedContacts

@synthesize contactsCount, sectionTitles, sectionedContacts;

-(id)initWithContacts:(NSArray<NSArray<MXKContact*> *> *)inSectionedContacts andTitles:(NSArray<NSString *> *)titles andCount:(int)count {
    if (self = [super init]) {
        contactsCount = count;
        sectionedContacts = inSectionedContacts;
        sectionTitles = titles;
    }
    return self;
}

@end
