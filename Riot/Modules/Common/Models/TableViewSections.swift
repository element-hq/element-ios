// 
// Copyright 2024 New Vector Ltd.
// Copyright 2020 Vector Creations Ltd
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

@objc
protocol TableViewSectionsDelegate {
    func tableViewSectionsDidUpdateSections(_ sections: TableViewSections)
}

@objcMembers
final class TableViewSections: NSObject {
    
    /// Delegate object
    weak var delegate: TableViewSectionsDelegate?
    
    /// Sections. Updating this will trigger `tableViewSectionsDidUpdateSections` of the delegate object.
    var sections: [Section] = [] {
        didSet {
            delegate?.tableViewSectionsDidUpdateSections(self)
        }
    }
    
    /// Finds the exact indexpath for the given row and section tag. If cannot find, returns nil
    /// - Parameters:
    ///   - rowTag: Tag for row
    ///   - sectionTag: Tag for section
    /// - Returns: IndexPath object if found, otherwise nil.
    func exactIndexPath(forRowTag rowTag: Int, sectionTag: Int) -> IndexPath? {
        guard let sectionIndex = sections.firstIndex(where: { $0.tag == sectionTag }) else {
            return nil
        }
        guard let indexOfRow = sections[sectionIndex].indexOfRow(withTag: rowTag) else {
            return nil
        }
        return IndexPath(row: indexOfRow, section: sectionIndex)
    }
    
    /// Finds the nearest next indexPath for given row tag and section tag. If the section finishes, also checks for the next section. If cannot find any row available, returns nil.
    /// - Parameters:
    ///   - rowTag: Tag for row
    ///   - sectionTag: Tag for section
    /// - Returns: IndexPath object if found, otherwise nil.
    func nearestIndexPath(forRowTag rowTag: Int, sectionTag: Int) -> IndexPath? {
        let sectionIndex = sections.firstIndex(where: { $0.tag == sectionTag })
        
        if let sectionIndex = sectionIndex {
            if let indexOfRow = sections[sectionIndex].indexOfRow(withTag: rowTag) {
                return IndexPath(row: indexOfRow, section: sectionIndex)
            } else if rowTag + 1 < sections[sectionIndex].rows.count {
                return nearestIndexPath(forRowTag: rowTag + 1, sectionTag: sectionTag)
            } else if sectionTag + 1 < sections.count {
                return nearestIndexPath(forRowTag: 0, sectionTag: sectionTag + 1)
            }
        } else if sectionTag + 1 < sections.count {
            //  try to return the first row of the next section
            return nearestIndexPath(forRowTag: 0, sectionTag: sectionTag + 1)
        }
        
        return nil
    }
    
    /// Section at index.
    /// - Parameter index: Index of desired section
    /// - Returns: Section object if index is in bounds of the sections array. Otherwise nil.
    func section(atIndex index: Int) -> Section? {
        if index < sections.count {
            return sections[index]
        }
        return nil
    }
    
    func tagsIndexPath(fromTableViewIndexPath indexPath: IndexPath) -> IndexPath? {
        guard let section = section(atIndex: indexPath.section) else {
            //  section not found
            return nil
        }
        guard indexPath.row < section.rows.count else {
            return nil
        }
        return IndexPath(row: section.rows[indexPath.row].tag, section: section.tag)
    }
    
}
