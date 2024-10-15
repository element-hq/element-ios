/*
Copyright 2024 New Vector Ltd.
Copyright 2015 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import <Foundation/Foundation.h>

#import "MXKContact.h"

@interface MXKSectionedContacts : NSObject {
    int contactsCount;
    NSArray<NSString*> *sectionTitles;
    NSArray<NSArray<MXKContact*>*> *sectionedContacts;
}

@property (nonatomic, readonly) int contactsCount;
@property (nonatomic, readonly) NSArray<NSString*> *sectionTitles;
@property (nonatomic, readonly) NSArray<NSArray<MXKContact*>*> *sectionedContacts;

- (instancetype)initWithContacts:(NSArray<NSArray<MXKContact*>*> *)inSectionedContacts andTitles:(NSArray<NSString*> *)titles andCount:(int)count;

@end
