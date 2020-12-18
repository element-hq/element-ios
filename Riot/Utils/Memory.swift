// 
// Copyright 2020 New Vector Ltd
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

/// Util class to log memory footprint and allocate memory for debugging purposes.
@objcMembers
class Memory: NSObject {
    
    /// Memory formatter, uses exact 2 fraction digits and no grouping
    private static var numberFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.alwaysShowsDecimalSeparator = true
        formatter.decimalSeparator = "."
        formatter.groupingSeparator = ""
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        return formatter
    }
    
    /// Details: https://developer.apple.com/forums/thread/105088
    /// - Returns: Current memory footprint
    private static func memoryFootprint() -> Float? {
        //  The `TASK_VM_INFO_COUNT` and `TASK_VM_INFO_REV1_COUNT` macros are too
        //  complex for the Swift C importer, so we have to define them ourselves.
        let TASK_VM_INFO_COUNT = mach_msg_type_number_t(MemoryLayout<task_vm_info_data_t>.size / MemoryLayout<integer_t>.size)
        guard let offset = MemoryLayout.offset(of: \task_vm_info_data_t.min_address) else {
            return nil
        }
        let TASK_VM_INFO_REV1_COUNT = mach_msg_type_number_t(offset / MemoryLayout<integer_t>.size)
        var info = task_vm_info_data_t()
        var count = TASK_VM_INFO_COUNT
        let kr = withUnsafeMutablePointer(to: &info) { infoPtr in
            infoPtr.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { intPtr in
                task_info(mach_task_self_, task_flavor_t(TASK_VM_INFO), intPtr, &count)
            }
        }
        guard kr == KERN_SUCCESS, count >= TASK_VM_INFO_REV1_COUNT else {
            return nil
        }
        
        return Float(info.phys_footprint)
    }
    
    /// Formatted memory footprint for debugging purposes
    /// - Returns: Memory footprint in MBs as a readable string
    static func formattedMemoryFootprint() -> String {
        let usedBytes = UInt64(self.memoryFootprint() ?? 0)
        let usedMB = Double(usedBytes) / 1024 / 1024
        guard let formattedStr = numberFormatter.string(from: NSNumber(value: usedMB)) else {
            return ""
        }
        return "\(formattedStr) MB"
    }
    
    /// Allocates some memory
    /// - Parameter numberOfBytes: Amount of memory to be allocated, in number of bytes
    static func allocateMemoryOfSize(numberOfBytes: Int) {
        var buffer = [UInt8](repeating: 0, count: numberOfBytes)
        for i in 0 ..< numberOfBytes {
            buffer[i] = UInt8(i % 7)
        }
    }
    
}
