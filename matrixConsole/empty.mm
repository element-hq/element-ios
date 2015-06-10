/*
 Copyright 2015 OpenMarket Ltd

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

 http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

#import <Foundation/Foundation.h>

/*
 This file exists only to force Xcode to use the GNU c++ standard library (libstdc++).
 Even if the project settings indicate they want to use libstdc++, if there is no .mm file, Xcode
 continues to use its c++ lib. That prevents the app from linking if it includes some .hh files.

 @see: http://stackoverflow.com/a/19250215/3936576

 */
