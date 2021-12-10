/*
 Copyright 2016 OpenMarket Ltd
 
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

#import <XCTest/XCTest.h>

#import "MXEncryptedAttachments.h"
#import "MXEncryptedContentFile.h"
#import "MXBase64Tools.h"

@interface EncryptedAttachmentsTest : XCTestCase

@end


@implementation EncryptedAttachmentsTest

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (void)testDecrypt {
    NSArray *testVectors =
        @[
             @[@"", @{
                 @"v": @"v1",
                 @"hashes": @{
                     @"sha256": @"47DEQpj8HBSa+/TImW+5JCeuQeRkm5NMpJWZG3hSuFU"
                 },
                 @"key": @{
                     @"alg": @"A256CTR",
                     @"k": @"AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA",
                     @"key_ops": @[@"encrypt", @"decrypt"],
                     @"kty": @"oct"
                 },
                 @"iv": @"AAAAAAAAAAAAAAAAAAAAAA"
             }, @""],
             @[@"5xJZTt5cQicm+9f4", @{
                 @"v": @"v1",
                 @"hashes": @{
                     @"sha256": @"YzF08lARDdOCzJpzuSwsjTNlQc4pHxpdHcXiD/wpK6k"
                 }, @"key": @{
                     @"alg": @"A256CTR",
                     @"k": @"__________________________________________8",
                     @"key_ops": @[@"encrypt", @"decrypt"],
                     @"kty": @"oct"
                 }, @"iv": @"//////////8AAAAAAAAAAA"
             }, @"SGVsbG8sIFdvcmxk"],
             @[@"zhtFStAeFx0s+9L/sSQO+WQMtldqYEHqTxMduJrCIpnkyer09kxJJuA4K+adQE4w+7jZe/vR9kIcqj9rOhDR8Q", @{
                @"v": @"v2",
                @"hashes": @{
                        @"sha256": @"IOq7/dHHB+mfHfxlRY5XMeCWEwTPmlf4cJcgrkf6fVU"
                        },
                @"key": @{
                        @"kty": @"oct",
                        @"key_ops": @[@"encrypt",@"decrypt"],
                        @"k": @"__________________________________________8",
                        @"alg": @"A256CTR"
                        },
                @"iv": @"//////////8AAAAAAAAAAA"
                }, @"YWxwaGFudW1lcmljYWxseWFscGhhbnVtZXJpY2FsbHlhbHBoYW51bWVyaWNhbGx5YWxwaGFudW1lcmljYWxseQ"],
             @[@"tJVNBVJ/vl36UQt4Y5e5m84bRUrQHhcdLPvS/7EkDvlkDLZXamBB6k8THbiawiKZ5Mnq9PZMSSbgOCvmnUBOMA", @{
                   @"v": @"v1",
                   @"hashes": @{
                           @"sha256": @"LYG/orOViuFwovJpv2YMLSsmVKwLt7pY3f8SYM7KU5E"
                   },
                   @"key": @{
                           @"kty": @"oct",
                           @"key_ops": @[@"encrypt",@"decrypt"],
                           @"k": @"__________________________________________8",
                           @"alg": @"A256CTR"
                   },
                   @"iv": @"/////////////////////w"
             }, @"YWxwaGFudW1lcmljYWxseWFscGhhbnVtZXJpY2FsbHlhbHBoYW51bWVyaWNhbGx5YWxwaGFudW1lcmljYWxseQ"]
        ];
    
    for (NSArray *vector in testVectors) {
        NSString *inputCiphertext = vector[0];
        MXEncryptedContentFile *inputInfo = [MXEncryptedContentFile modelFromJSON:vector[1]];
        NSString *want = vector[2];
        
        NSData *ctData = [[NSData alloc] initWithBase64EncodedString:[MXBase64Tools padBase64:inputCiphertext] options:0];
        NSInputStream *inputStream = [NSInputStream inputStreamWithData:ctData];
        NSOutputStream *outputStream = [NSOutputStream outputStreamToMemory];
        
        [MXEncryptedAttachments decryptAttachment:inputInfo inputStream:inputStream outputStream:outputStream success:^{
            NSData *gotData = [outputStream propertyForKey:NSStreamDataWrittenToMemoryStreamKey];
            
            NSData *wantData = [[NSData alloc] initWithBase64EncodedString:[MXBase64Tools padBase64:want] options:0];
            
            XCTAssertEqualObjects(wantData, gotData, "Decrypted data did not match expectation.");
        } failure:^(NSError *error) {
            XCTFail();
        }];
    }
}

@end
