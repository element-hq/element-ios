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

#import "NSString+Riot.h"

@implementation NSString (Riot)

+ (NSString*)stringSuffixedWithNumber:(NSNumber*)number
{
    if (!number)
    {
        return @"";
    }

    long long num = [number longLongValue];

    int s = ( (num < 0) ? -1 : (num > 0) ? 1 : 0 );
    NSString* sign = (s == -1 ? @"-" : @"" );

    num = llabs(num);

    if (num < 1000)
    {
        return [NSString stringWithFormat:@"%@%lld",sign,num];
    }

    int exp = (int) (log10l(num) / 3.f);

    NSArray* units = @[@"K",@"M",@"G",@"T",@"P",@"E"];

    NSNumberFormatter *formatter = [NSNumberFormatter new];
    formatter.positiveSuffix = [units objectAtIndex:(exp-1)];
    formatter.negativeSuffix = [units objectAtIndex:(exp-1)];
    formatter.allowsFloats = YES;
    formatter.minimumIntegerDigits = 1;
    formatter.minimumFractionDigits = 0;
    formatter.maximumFractionDigits = 1;

    return [NSString stringWithFormat:@"%@%@", sign, [formatter stringFromNumber:@((num / pow(1000, exp)))]];
}

@end
