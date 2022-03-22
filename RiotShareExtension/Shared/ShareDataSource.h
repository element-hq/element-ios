/*
 Copyright 2017 Aram Sargsyan
 
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

#import "MatrixKit.h"

@class ShareDataSource;

@protocol ShareDataSourceDelegate <NSObject>

- (void)shareDataSourceDidChangeSelectedRoomIdentifiers:(ShareDataSource *)shareDataSource;

@end

@interface ShareDataSource : MXKRecentsDataSource

@property (nonatomic, weak) id<ShareDataSourceDelegate> shareDelegate;

@property (nonatomic, strong, readonly) NSSet<NSString *> *selectedRoomIdentifiers;

- (instancetype)initWithFileStore:(MXFileStore *)fileStore
                          session:(MXSession *)session;

- (void)selectRoomWithIdentifier:(NSString *)roomIdentifier animated:(BOOL)animated;

- (void)deselectRoomWithIdentifier:(NSString *)roomIdentifier animated:(BOOL)animated;

@end
