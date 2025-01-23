// 
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

#ifndef AllChatsLayoutModels_h
#define AllChatsLayoutModels_h

typedef NS_OPTIONS(NSUInteger, AllChatsLayoutSectionType) {
    AllChatsLayoutSectionTypeRecents     = 1 << 0,
    AllChatsLayoutSectionTypeFavourites  = 1 << 1
};

typedef NS_OPTIONS(NSUInteger, AllChatsLayoutFilterType) {
    AllChatsLayoutFilterTypeAll          = 1 << 0,
    AllChatsLayoutFilterTypePeople       = 1 << 1,
    AllChatsLayoutFilterTypeRooms        = 1 << 2,
    AllChatsLayoutFilterTypeFavourites   = 1 << 3,
    AllChatsLayoutFilterTypeUnreads      = 1 << 4
};

typedef NS_ENUM(NSUInteger, AllChatsLayoutSortingType) {
    AllChatsLayoutSortingTypeActivity,
    AllChatsLayoutSortingTypeAlphabetical
};

#endif /* AllChatsLayoutModels_h */
