// 
// Copyright 2020 Vector Creations Ltd
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
