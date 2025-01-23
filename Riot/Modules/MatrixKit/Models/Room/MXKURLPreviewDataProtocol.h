// 
// Copyright 2024 New Vector Ltd.
// Copyright 2020 The Matrix.org Foundation C.I.C
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
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
