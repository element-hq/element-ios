// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import CoreData

extension URLPreviewDataMO {
    convenience init(context: NSManagedObjectContext, preview: URLPreviewData, creationDate: Date) {
        self.init(context: context)
        update(from: preview, on: creationDate)
    }
    
    func update(from preview: URLPreviewData, on date: Date) {
        url = preview.url
        siteName = preview.siteName
        title = preview.title
        text = preview.text
        image = preview.image
        
        creationDate = date
    }
    
    func preview(for event: MXEvent) -> URLPreviewData? {
        guard let url = url else { return nil }
        
        let viewData = URLPreviewData(url: url,
                                      eventID: event.eventId,
                                      roomID: event.roomId,
                                      siteName: siteName,
                                      title: title,
                                      text: text)
        viewData.image = image as? UIImage
        
        return viewData
    }
}
