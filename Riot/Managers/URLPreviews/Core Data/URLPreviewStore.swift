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

import CoreData

/// A cache for URL previews backed by Core Data.
class URLPreviewStore {
    
    // MARK: - Properties
    
    /// The Core Data container for persisting the cache to disk.
    private let container: NSPersistentContainer
    
    /// The Core Data context used to store and load data on.
    private var context: NSManagedObjectContext {
        container.viewContext
    }
    
    /// A time interval that represents how long an item in the cache is valid for.
    private let dataValidityTime: TimeInterval = 60 * 60 * 24
    
    /// The oldest `creationDate` allowed for valid data.
    private var expiryDate: Date {
        Date().addingTimeInterval(-dataValidityTime)
    }
    
    // MARK: - Lifecycle
    
    /// Create a URLPreview Cache optionally storing the data in memory.
    /// - Parameter inMemory: Whether to store the data in memory.
    init(inMemory: Bool = false) {
        // Register the transformer for the `image` field.
        ValueTransformer.setValueTransformer(URLPreviewImageTransformer(), forName: .urlPreviewImageTransformer)
        
        // Create the container, updating it's path if storing the data in memory.
        container = NSPersistentContainer(name: "URLPreviewStore")
        
        if inMemory {
            if let storeDescription = container.persistentStoreDescriptions.first {
                storeDescription.url = CoreDataHelper.inMemoryURL
            } else {
                MXLog.error("[URLPreviewStore] persistentStoreDescription not found.")
            }
        }
        
        // Load the persistent stores into the container
        container.loadPersistentStores { storeDescription, error in
            if let error = error {
                MXLog.error("[URLPreviewStore] Core Data container", context: error)
            }
            
            if let url = storeDescription.url {
                do {
                    try FileManager.default.excludeItemFromBackup(at: url)
                } catch {
                    MXLog.error("[URLPreviewStore] Cannot exclude Core Data from backup", context: error)
                }
            }
        }
    }
    
    // MARK: - Public
    
    /// Cache a preview in the store. If a preview already exists with the same URL it will be updated from the new preview.
    /// - Parameter preview: The preview to add to the store.
    /// - Parameter date: Optional: The date the preview was generated. When nil, the current date is assigned.
    func cache(_ preview: URLPreviewData, generatedOn generationDate: Date? = nil) {
        // Create a fetch request for an existing preview.
        let request: NSFetchRequest<URLPreviewDataMO> = URLPreviewDataMO.fetchRequest()
        request.predicate = NSPredicate(format: "url == %@", preview.url as NSURL)
        
        // Use the custom date if supplied (currently this is for testing purposes)
        let date = generationDate ?? Date()
        
        // Update existing data if found otherwise create new data.
        if let cachedPreview = try? context.fetch(request).first {
            cachedPreview.update(from: preview, on: date)
        } else {
            _ = URLPreviewDataMO(context: context, preview: preview, creationDate: date)
        }
        
        save()
    }
    
    /// Fetches the preview from the cache for the supplied URL. If a preview doesn't exist or
    /// if the preview is older than the ``dataValidityTime`` the returned value will be nil.
    /// - Parameter url: The URL to fetch the preview for.
    /// - Returns: The preview if found, otherwise nil.
    func preview(for url: URL, and event: MXEvent) -> URLPreviewData? {
        // Create a request for the url excluding any expired items
        let request: NSFetchRequest<URLPreviewDataMO> = URLPreviewDataMO.fetchRequest()
        request.predicate = NSCompoundPredicate(type: .and, subpredicates: [
            NSPredicate(format: "url == %@", url as NSURL),
            NSPredicate(format: "creationDate > %@", expiryDate as NSDate)
        ])
        
        // Fetch the request, returning nil if nothing was found
        guard
            let cachedPreview = try? context.fetch(request).first
        else { return nil }
        
        // Convert and return
        return cachedPreview.preview(for: event)
    }
    
    /// Returns the number of URL previews cached in the store.
    func cacheCount() -> Int {
        let request: NSFetchRequest<NSFetchRequestResult> = URLPreviewDataMO.fetchRequest()
        return (try? context.count(for: request)) ?? 0
    }
    
    /// Removes any expired cache data from the store.
    func removeExpiredItems() {
        let request: NSFetchRequest<NSFetchRequestResult> = URLPreviewDataMO.fetchRequest()
        request.predicate = NSPredicate(format: "creationDate < %@", expiryDate as NSDate)
        
        do {
            try context.execute(NSBatchDeleteRequest(fetchRequest: request))
        } catch {
            MXLog.error("[URLPreviewStore] Error executing batch delete request", context: error)
        }
    }
    
    /// Deletes all cache data and all closed previews from the store.
    func deleteAll() {
        do {
            _ = try context.execute(NSBatchDeleteRequest(fetchRequest: URLPreviewDataMO.fetchRequest()))
            _ = try context.execute(NSBatchDeleteRequest(fetchRequest: URLPreviewUserDataMO.fetchRequest()))
        } catch {
            MXLog.error("[URLPreviewStore] Error executing batch delete request", context: error)
        }
    }
    
    /// Store the dismissal of a preview from the event with `eventId` and `roomId`.
    func closePreview(for eventId: String, in roomId: String) {
        _ = URLPreviewUserDataMO(context: context, eventID: eventId, roomID: roomId, dismissed: true)
        save()
    }
    
    /// Whether a preview for an event with the given `eventId` and `roomId` has been closed or not.
    func hasClosedPreview(for eventId: String, in roomId: String) -> Bool {
        // Create a request for the url excluding any expired items
        let request: NSFetchRequest<URLPreviewUserDataMO> = URLPreviewUserDataMO.fetchRequest()
        request.predicate = NSCompoundPredicate(type: .and, subpredicates: [
            NSPredicate(format: "eventID == %@", eventId),
            NSPredicate(format: "roomID == %@", roomId),
            NSPredicate(format: "dismissed == true")
        ])
        
        return (try? context.count(for: request)) ?? 0 > 0
    }
    
    // MARK: - Private
    
    /// Saves any changes that are found on the context
    private func save() {
        guard context.hasChanges else { return }
        do {
            try context.save()
        } catch {
            MXLog.error("[URLPreviewStore] Error saving changes", context: error)
        }
    }
}
