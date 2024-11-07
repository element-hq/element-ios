/*
Copyright 2024 New Vector Ltd.
Copyright 2015 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
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
