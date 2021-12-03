/*
 Copyright 2017 Vector Creations Ltd
 
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

#import <UIKit/UIKit.h>

/**
 `MXKView` is a base class used to add some functionalities to the UIView class.
 */
@interface MXKView : UIView

/**
 Customize the rendering of the view and its subviews (Do nothing by default).
 This method is called automatically when the view is initialized or loaded from an Interface Builder archive (or nib file).
 
 Override this method to customize the view instance at the application level.
 It may be used to handle different rendering themes. In this case this method should be called whenever the theme has changed.
 */
- (void)customizeViewRendering;

@end

