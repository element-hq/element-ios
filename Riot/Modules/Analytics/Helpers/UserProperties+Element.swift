// 
// Copyright 2021 New Vector Ltd
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

import Foundation
import AnalyticsEvents

extension AnalyticsEvent.UserProperties {

    //  Initializer for Element. Strips all Web properties.
    public init(ftueUseCaseSelection: FtueUseCaseSelection?, numFavouriteRooms: Int?, numSpaces: Int?, allChatsActiveFilter: AllChatsActiveFilter?) {
        self.init(WebMetaSpaceFavouritesEnabled: nil,
                  WebMetaSpaceHomeAllRooms: nil,
                  WebMetaSpaceHomeEnabled: nil,
                  WebMetaSpaceOrphansEnabled: nil,
                  WebMetaSpacePeopleEnabled: nil,
                  allChatsActiveFilter: allChatsActiveFilter,
                  ftueUseCaseSelection: ftueUseCaseSelection,
                  numFavouriteRooms: numFavouriteRooms,
                  numSpaces: numSpaces)
    }

}
