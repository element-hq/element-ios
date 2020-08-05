// 
// Copyright 2020 Vector Creations Ltd
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

#import "Section.h"
#import "Row.h"

@implementation Section

+ (instancetype)sectionWithTag:(NSInteger)tag
{
    return [[self alloc] initWithTag:tag];
}

- (instancetype)initWithTag:(NSInteger)tag
{
    self = [super init];
    if (self) {
        self.tag = tag;
        _rows = [NSMutableArray arrayWithCapacity:10];
    }
    return self;
}

- (void)addRow:(Row *)row
{
    [_rows addObject:row];
}

- (void)addRowWithTag:(NSInteger)tag
{
    [_rows addObject:[Row rowWithTag:tag]];
}

- (NSInteger)indexOfRowForTag:(NSInteger)tag
{
    return [_rows indexOfObjectPassingTest:^BOOL(Row * _Nonnull row, NSUInteger idx, BOOL * _Nonnull stop) {
        return row.tag == tag;
    }];
}

@end
