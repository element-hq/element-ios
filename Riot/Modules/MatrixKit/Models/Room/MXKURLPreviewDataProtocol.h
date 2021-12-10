// 
// Copyright 2020 The Matrix.org Foundation C.I.C
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

@protocol MXKURLPreviewDataProtocol <NSObject>

/// The URL that's represented by the preview data.
@property (readonly, nonnull) NSURL *url;

/// The ID of the event that created this preview.
@property (readonly, nonnull) NSString *eventID;

/// The ID of the room that this preview is from.
@property (readonly, nonnull) NSString *roomID;

/// The OpenGraph site name for the URL.
@property (readonly, nullable) NSString *siteName;

/// The OpenGraph title for the URL.
@property (readonly, nullable) NSString *title;

/// The OpenGraph description for the URL.
@property (readonly, nullable) NSString *text;

/// The OpenGraph image for the URL.
@property (readwrite, nullable) UIImage *image;

@end
