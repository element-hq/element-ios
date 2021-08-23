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
class URLPreviewCache {
    
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
        container = NSPersistentContainer(name: "URLPreviewCache")
        
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }
        
        // Load the persistent stores into the container
        container.loadPersistentStores { storeDescription, error in
            if let error = error {
                MXLog.error("[URLPreviewCache] Core Data container error: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Public
    
    /// Store a preview in the cache. If a preview already exists with the same URL it will be updated from the new preview.
    /// - Parameter preview: The preview to add to the cache.
    /// - Parameter date: Optional: The date the preview was generated.
    func store(_ preview: URLPreviewViewData, generatedOn generationDate: Date? = nil) {
        // Create a fetch request for an existing preview.
        let request: NSFetchRequest<URLPreviewCacheData> = URLPreviewCacheData.fetchRequest()
        request.predicate = NSPredicate(format: "url == %@", preview.url as NSURL)
        
        // Use the custom date if supplied (currently this is for testing purposes)
        let date = generationDate ?? Date()
        
        // Update existing data if found otherwise create new data.
        if let cachedPreview = try? context.fetch(request).first {
            cachedPreview.update(from: preview, on: date)
        } else {
            _ = URLPreviewCacheData(context: context, preview: preview, creationDate: date)
        }
        
        save()
    }
    
    /// Fetches the preview from the cache for the supplied URL. If a preview doesn't exist or
    /// if the preview is older than the ``dataValidityTime`` the returned value will be nil.
    /// - Parameter url: The URL to fetch the preview for.
    /// - Returns: The preview if found, otherwise nil.
    func preview(for url: URL) -> URLPreviewViewData? {
        // Create a request for the url excluding any expired items
        let request: NSFetchRequest<URLPreviewCacheData> = URLPreviewCacheData.fetchRequest()
        request.predicate = NSCompoundPredicate(type: .and, subpredicates: [
            NSPredicate(format: "url == %@", url as NSURL),
            NSPredicate(format: "creationDate > %@", expiryDate as NSDate)
        ])
        
        // Fetch the request, returning nil if nothing was found
        guard
            let cachedPreview = try? context.fetch(request).first
        else { return nil }
        
        // Convert and return
        return cachedPreview.preview()
    }
    
    func count() -> Int {
        let request: NSFetchRequest<NSFetchRequestResult> = URLPreviewCacheData.fetchRequest()
        return (try? context.count(for: request)) ?? 0
    }
    
    func removeExpiredItems() {
        let request: NSFetchRequest<NSFetchRequestResult> = URLPreviewCacheData.fetchRequest()
        request.predicate = NSPredicate(format: "creationDate < %@", expiryDate as NSDate)
        
        do {
            try context.execute(NSBatchDeleteRequest(fetchRequest: request))
        } catch {
            MXLog.error("[URLPreviewCache] Error executing batch delete request: \(error.localizedDescription)")
        }
    }
    
    func clear() {
        do {
            _ = try context.execute(NSBatchDeleteRequest(fetchRequest: URLPreviewCacheData.fetchRequest()))
        } catch {
            MXLog.error("[URLPreviewCache] Error executing batch delete request: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Private
    
    /// Saves any changes that are found on the context
    private func save() {
        guard context.hasChanges else { return }
        try? context.save()
    }
}
