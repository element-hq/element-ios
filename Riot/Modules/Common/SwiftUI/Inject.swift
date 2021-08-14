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

@propertyWrapper struct Inject<Value> {
    
    static subscript<T: Injectable>(
        _enclosingInstance instance: T,
        wrapped wrappedKeyPath: ReferenceWritableKeyPath<T, Value>,
        storage storageKeyPath: ReferenceWritableKeyPath<T, Self>
    ) -> Value {
        get {
            let v: Value = instance.dependencies.resolve()
            return v
        }
        set {
            fatalError()
        }
    }
    
    @available(*, unavailable,
    message: "@Published can only be applied to classes"
    )
    var wrappedValue: Value {
        get { fatalError() }
        set { fatalError(" \(newValue)" ) }
    }
}
