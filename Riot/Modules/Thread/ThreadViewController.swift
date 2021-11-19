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

class ThreadViewController: RoomViewController {
    
    // MARK: Private
    
    private(set) var threadId: String!
    
    class func instantiate(withThreadId threadId: String,
                           configuration: RoomDisplayConfiguration) -> ThreadViewController {
        let threadVC = ThreadViewController.instantiate(with: configuration)
        threadVC.threadId = threadId
        return threadVC
    }
    
    override class func nib() -> UINib! {
        //  reuse 'RoomViewController.xib' file as the nib
        return UINib(nibName: String(describing: RoomViewController.self), bundle: .main)
    }
    
    override func setRoomTitleViewClass(_ roomTitleViewClass: AnyClass!) {
        super.setRoomTitleViewClass(ThreadRoomTitleView.self)
        
        guard let threadTitleView = self.titleView as? ThreadRoomTitleView else {
            return
        }
        
        threadTitleView.threadId = threadId
    }
    
}
