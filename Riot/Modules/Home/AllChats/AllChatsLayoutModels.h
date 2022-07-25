// 
// Copyright 2022 New Vector Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
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
