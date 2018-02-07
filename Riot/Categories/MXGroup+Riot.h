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

#import <MatrixKit/MatrixKit.h>

/**
 Define a `MXGroup` category at Riot level.
 */
@interface MXGroup (Riot)

/**
 Set the group avatar in the dedicated MXKImageView.
 The riot style implies to use in order :
 1 - the default avatar if there is one
 2 - the first letter of the group name.
 
 @param mxkImageView the destinated MXKImageView.
 @param mxSession the matrix session 
 */
- (void)setGroupAvatarImageIn:(MXKImageView*)mxkImageView matrixSession:(MXSession*)mxSession;

@end
