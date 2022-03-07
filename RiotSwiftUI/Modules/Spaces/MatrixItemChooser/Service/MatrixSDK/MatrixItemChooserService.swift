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
import Combine

protocol MatrixItemChooserDataSource {
    func sections(with session: MXSession, completion: @escaping (Result<[MatrixListItemSectionData], Error>) -> Void)
    var preselectedItemIds: Set<String>? { get }
}

protocol MatrixItemChooserProcessorProtocol {
    var loadingText: String? { get }
    var dataSource: MatrixItemChooserDataSource { get }
    func computeSelection(withIds itemsIds:[String], completion: @escaping (Result<Void, Error>) -> Void)
    func isItemIncluded(_ item: (MatrixListItemData)) -> Bool
}

@available(iOS 14.0, *)
class MatrixItemChooserService: MatrixItemChooserServiceProtocol {

    // MARK: - Properties
    
    // MARK: Private
    
    private let processingQueue = DispatchQueue(label: "io.element.MatrixItemChooserService.processingQueue")
    private let completionQueue = DispatchQueue.main

    private let session: MXSession
    private var sections: [MatrixListItemSectionData] = []
    private var filteredSections: [MatrixListItemSectionData] = [] {
        didSet {
            sectionsSubject.send(filteredSections)
        }
    }
    private var selectedItemIds: Set<String>
    private let itemsProcessor: MatrixItemChooserProcessorProtocol
    
    // MARK: Public
    
    private(set) var sectionsSubject: CurrentValueSubject<[MatrixListItemSectionData], Never>
    private(set) var selectedItemIdsSubject: CurrentValueSubject<Set<String>, Never>
    var searchText: String = "" {
        didSet {
            refresh()
        }
    }
    var loadingText: String? {
        itemsProcessor.loadingText
    }

    // MARK: - Setup
    
    init(session: MXSession, selectedItemIds: [String], itemsProcessor: MatrixItemChooserProcessorProtocol) {
        self.session = session
        self.sectionsSubject = CurrentValueSubject(self.sections)
        
        self.selectedItemIds = Set(selectedItemIds)
        self.selectedItemIdsSubject = CurrentValueSubject(self.selectedItemIds)
        self.itemsProcessor = itemsProcessor
        
        itemsProcessor.dataSource.sections(with: session) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let sections):
                self.sections = sections
                self.refresh()
                if let preselectedItemIds = itemsProcessor.dataSource.preselectedItemIds {
                    for itemId in preselectedItemIds {
                        self.selectedItemIds.insert(itemId)
                    }
                    self.selectedItemIdsSubject.send(self.selectedItemIds)
                }
            case .failure(let error):
                break
            }
        }

        refresh()
    }
    
    // MARK: - Public
    
    func reverseSelectionForItem(withId itemId: String) {
        if selectedItemIds.contains(itemId) {
            selectedItemIds.remove(itemId)
        } else {
            selectedItemIds.insert(itemId)
        }
        selectedItemIdsSubject.send(selectedItemIds)
    }
    
    func processSelection(completion: @escaping (Result<Void, Error>) -> Void) {
        itemsProcessor.computeSelection(withIds: Array(selectedItemIds), completion: completion)
    }
    
    func refresh() {
        self.processingQueue.async { [weak self] in
            guard let self = self else { return }
            let filteredSections = self.filter(sections: self.sections)
            
            self.completionQueue.async {
                self.filteredSections = filteredSections
            }
        }
    }

    // MARK: - Private
    
    private func filter(sections: [MatrixListItemSectionData]) -> [MatrixListItemSectionData] {
        var newSections: [MatrixListItemSectionData] = []
        
        for section in sections {
            let items: [MatrixListItemData]
            if searchText.isEmpty {
                items = section.items.filter {
                    itemsProcessor.isItemIncluded($0)
                }
            } else {
                let lowercasedSearchText = self.searchText.lowercased()
                items = section.items.filter {
                    itemsProcessor.isItemIncluded($0) && ($0.id.lowercased().contains(lowercasedSearchText) || ($0.displayName ?? "").lowercased().contains(lowercasedSearchText))
                }
            }
            newSections.append(MatrixListItemSectionData(id: section.id, title: section.title, infoText: section.infoText, items: items))
        }
        
        return newSections
    }
}
