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

@objc
protocol CallPresenterDelegate: class {
    //  New call
    func callPresenter(_ presenter: CallPresenter,
                       shouldHandleNewCall call: MXCall) -> Bool
    
    //  Call screens
    func callPresenter(_ presenter: CallPresenter,
                       presentCallViewController viewController: CallViewController,
                       completion:(() -> Void)?)
    func callPresenter(_ presenter: CallPresenter,
                       dismissCallViewController viewController: CallViewController,
                       completion:(() -> Void)?)
    
    //  Call Bar
    func callPresenter(_ presenter: CallPresenter,
                       presentCallBarFor activeCallViewController: CallViewController?,
                       numberOfPausedCalls: UInt,
                       completion:(() -> Void)?)
    func callPresenter(_ presenter: CallPresenter,
                       dismissCallBar completion:(() -> Void)?)
    
    //  PiP
    func callPresenter(_ presenter: CallPresenter,
                       enterPipForCallViewController viewController: CallViewController,
                       completion:(() -> Void)?)
    
    func callPresenter(_ presenter: CallPresenter,
                       exitPipForCallViewController viewController: CallViewController,
                       completion:(() -> Void)?)
}
