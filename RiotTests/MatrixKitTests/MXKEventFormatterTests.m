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

#import "MatrixKit.h"
#import "MXKEventFormatter+Tests.h"

@import DTCoreText;

@interface MXKEventFormatterTests : XCTestCase
{
    MXKEventFormatter *eventFormatter;
    MXEvent *anEvent;
    CGFloat maxHeaderSize;
}

@end

@implementation MXKEventFormatterTests

- (void)setUp
{
    [super setUp];

    // Create a minimal event formatter
    // Note: it may not be enough for testing all MXKEventFormatter methods
    eventFormatter = [[MXKEventFormatter alloc] initWithMatrixSession:nil];

    eventFormatter.treatMatrixUserIdAsLink = YES;
    eventFormatter.treatMatrixRoomIdAsLink = YES;
    eventFormatter.treatMatrixRoomAliasAsLink = YES;
    eventFormatter.treatMatrixEventIdAsLink = YES;
    
    anEvent = [[MXEvent alloc] init];
    anEvent.roomId = @"aRoomId";
    anEvent.eventId = @"anEventId";
    anEvent.wireType = kMXEventTypeStringRoomMessage;
    anEvent.originServerTs = (uint64_t) ([[NSDate date] timeIntervalSince1970] * 1000);
    anEvent.wireContent = @{ kMXMessageTypeKey: kMXMessageTypeText,
                             kMXMessageBodyKey: @"deded" };
    
    maxHeaderSize = ceil(eventFormatter.defaultTextFont.pointSize * 1.2);
}

- (void)tearDown
{
    [super tearDown];
}

- (void)testRenderHTMLStringWithHeaders
{
    // Given HTML strings with h1/h2/h3 tags
    NSString *h1HTML = @"<h1>Large Heading</h1>";
    NSString *h2HTML = @"<h2>Smaller Heading</h2>";
    NSString *h3HTML = @"<h3>Acceptable Heading</h3>";
    
    // When rendering these strings as attributed strings
    NSAttributedString *h1AttributedString = [eventFormatter renderHTMLString:h1HTML
                                                                     forEvent:anEvent
                                                                withRoomState:nil
                                                           andLatestRoomState:nil];
    NSAttributedString *h2AttributedString = [eventFormatter renderHTMLString:h2HTML
                                                                     forEvent:anEvent
                                                                withRoomState:nil
                                                           andLatestRoomState:nil];
    NSAttributedString *h3AttributedString = [eventFormatter renderHTMLString:h3HTML
                                                                     forEvent:anEvent
                                                                withRoomState:nil
                                                           andLatestRoomState:nil];
    
    // Then the h1/h2 fonts should be reduced in size to match h3.
    XCTAssertEqualObjects(h1AttributedString.string, @"Large Heading", @"The text from an H1 tag should be preserved when removing formatting.");
    XCTAssertEqualObjects(h2AttributedString.string, @"Smaller Heading", @"The text from an H2 tag should be preserved when removing formatting.");
    XCTAssertEqualObjects(h3AttributedString.string, @"Acceptable Heading", @"The text from an H3 tag should not change.");
    
    [h1AttributedString enumerateAttributesInRange:NSMakeRange(0, h1AttributedString.length)
                                         options:0
                                      usingBlock:^(NSDictionary<NSAttributedStringKey,id> * _Nonnull attributes, NSRange range, BOOL * _Nonnull stop) {
        UIFont *font = attributes[NSFontAttributeName];
        XCTAssertGreaterThan(font.pointSize, eventFormatter.defaultTextFont.pointSize, @"H1 tags should be larger than the default body size.");
        XCTAssertLessThanOrEqual(font.pointSize, maxHeaderSize, @"H1 tags shouldn't exceed the max header size.");
    }];
    
    [h2AttributedString enumerateAttributesInRange:NSMakeRange(0, h2AttributedString.length)
                                         options:0
                                      usingBlock:^(NSDictionary<NSAttributedStringKey,id> * _Nonnull attributes, NSRange range, BOOL * _Nonnull stop) {
        UIFont *font = attributes[NSFontAttributeName];
        XCTAssertGreaterThan(font.pointSize, eventFormatter.defaultTextFont.pointSize, @"H2 tags should be larger than the default body size.");
        XCTAssertLessThanOrEqual(font.pointSize, maxHeaderSize, @"H2 tags shouldn't exceed the max header size.");
    }];
    
    [h3AttributedString enumerateAttributesInRange:NSMakeRange(0, h3AttributedString.length)
                                         options:0
                                      usingBlock:^(NSDictionary<NSAttributedStringKey,id> * _Nonnull attributes, NSRange range, BOOL * _Nonnull stop) {
        UIFont *font = attributes[NSFontAttributeName];
        XCTAssertGreaterThan(font.pointSize, eventFormatter.defaultTextFont.pointSize, @"H3 tags should be included and be larger than the default body size.");
        XCTAssertLessThanOrEqual(font.pointSize, maxHeaderSize, @"H3 tags shouldn't exceed the max header size.");
    }];
}

- (void)testRenderHTMLStringWithPreCode
{
    NSString *html = @"<pre><code>1\n2\n3\n4\n</code></pre>";
    NSAttributedString *as = [eventFormatter renderHTMLString:html
                                                     forEvent:anEvent
                                                withRoomState:nil
                                           andLatestRoomState:nil];

    NSString *a = as.string;

    // \R : any newlines
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"\\R" options:0 error:0];
    XCTAssertEqual(3, [regex numberOfMatchesInString:a options:0 range:NSMakeRange(0, a.length)], "renderHTMLString must keep line break in <pre> and <code> blocks");

    [as enumerateAttributesInRange:NSMakeRange(0, as.length) options:(0) usingBlock:^(NSDictionary<NSString *,id> * _Nonnull attrs, NSRange range, BOOL * _Nonnull stop) {

        UIFont *font = attrs[NSFontAttributeName];
        XCTAssertEqualObjects(font.fontName, @"Menlo-Regular", "The font for <pre> and <code> should be monospace");
    }];
}

- (void)testRenderHTMLStringWithLink
{
    // Given an HTML string with a link inside of it.
    NSString *html = @"This text contains a <a href=\"https://www.matrix.org/\">link</a>.";
    
    // When rendering this string as an attributed string.
    NSAttributedString *attributedString = [eventFormatter renderHTMLString:html
                                                                   forEvent:anEvent
                                                              withRoomState:nil
                                                         andLatestRoomState:nil];
    
    // Then the attributed string should contain all of the text,
    XCTAssertEqualObjects(attributedString.string, @"This text contains a link.", @"The text should be preserved when adding a link.");
    
    // and the link should be added as an attachment.
    __block BOOL didFindLink = NO;
    [attributedString enumerateAttribute:NSLinkAttributeName
                                 inRange:NSMakeRange(0, attributedString.length)
                                 options:0
                              usingBlock:^(id _Nullable value, NSRange range, BOOL * _Nonnull stop) {
        if ([value isKindOfClass:NSURL.class])
        {
            NSURL *url = (NSURL *)value;
            XCTAssertEqualObjects(url, [NSURL URLWithString:@"https://www.matrix.org/"], @"href links should be included in the text.");
            didFindLink = YES;
        }
    }];
    
    XCTAssertTrue(didFindLink, @"There should be a link in the attributed string.");
}

- (void)testRenderHTMLStringWithLinkInHeader
{
    // Given HTML strings with links contained within h1/h2 tags.
    NSString *h1HTML = @"<h1><a href=\"https://www.matrix.org/\">Matrix.org</a></h1>";
    NSString *h3HTML = @"<h3><a href=\"https://www.matrix.org/\">Matrix.org</a></h3>";
    
    // When rendering these strings as attributed strings.
    NSAttributedString *h1AttributedString = [eventFormatter
                                              renderHTMLString:h1HTML
                                              forEvent:anEvent
                                              withRoomState:nil
                                              andLatestRoomState:nil];
    NSAttributedString *h3AttributedString = [eventFormatter
                                              renderHTMLString:h3HTML
                                              forEvent:anEvent
                                              withRoomState:nil
                                              andLatestRoomState:nil];
    
    // Then the attributed string should contain all of the text,
    XCTAssertEqualObjects(h1AttributedString.string, @"Matrix.org", @"The text from an H1 tag should be preserved when removing formatting.");
    XCTAssertEqualObjects(h3AttributedString.string, @"Matrix.org", @"The text from an H3 tag should not change.");
    
    // and be formatted as a header with the link added as an attachment.
    __block BOOL didFindH1Link = NO;
    [h1AttributedString enumerateAttributesInRange:NSMakeRange(0, h1AttributedString.length)
                                         options:0
                                      usingBlock:^(NSDictionary<NSAttributedStringKey,id> * _Nonnull attributes, NSRange range, BOOL * _Nonnull stop) {
        UIFont *font = attributes[NSFontAttributeName];
        NSURL *url = attributes[NSLinkAttributeName];
        
        if (font)
        {
            XCTAssertGreaterThan(font.pointSize, eventFormatter.defaultTextFont.pointSize, @"H1 tags should be larger than the default body size.");
            XCTAssertLessThanOrEqual(font.pointSize, maxHeaderSize, @"H1 tags shouldn't exceed the max header size.");
        }
        
        if (url)
        {
            XCTAssertEqualObjects(url, [NSURL URLWithString:@"https://www.matrix.org/"], @"href links should be included in the text.");
            didFindH1Link = YES;
        }
    }];
    
    __block BOOL didFindH3Link = NO;
    [h3AttributedString enumerateAttributesInRange:NSMakeRange(0, h3AttributedString.length)
                                         options:0
                                      usingBlock:^(NSDictionary<NSAttributedStringKey,id> * _Nonnull attributes, NSRange range, BOOL * _Nonnull stop) {
        UIFont *font = attributes[NSFontAttributeName];
        NSURL *url = attributes[NSLinkAttributeName];
        
        if (font)
        {
            XCTAssertGreaterThan(font.pointSize, eventFormatter.defaultTextFont.pointSize, @"H3 tags should be included and be larger than the default.");
        }
        
        if (url)
        {
            XCTAssertEqualObjects(url, [NSURL URLWithString:@"https://www.matrix.org/"], @"href links should be included in the text.");
            didFindH3Link = YES;
        }
    }];
    
    XCTAssertTrue(didFindH1Link, @"There should be a link in the sanitised attributed string.");
    XCTAssertTrue(didFindH3Link, @"There should be a link in the attributed string.");
}

- (void)testRenderHTMLStringWithIFrame
{
    // Given an HTML string containing an unsupported iframe.
    NSString *html = @"<iframe src=\"https://www.matrix.org/\"></iframe>";
    
    // When rendering this string as an attributed string.
    NSAttributedString *attributedString = [eventFormatter renderHTMLString:html
                                                                   forEvent:anEvent
                                                              withRoomState:nil
                                                         andLatestRoomState:nil];
    
    // Then the attributed string should have the iframe stripped and not include any attachments.
    BOOL hasAttachment = [attributedString containsAttachmentsInRange:NSMakeRange(0, attributedString.length)];
    XCTAssertFalse(hasAttachment, @"iFrame attachments should be removed as they're not included in the allowedHTMLTags array.");
}

- (void)testRenderHTMLStringWithMXReply
{
    // Given an HTML string representing a matrix reply.
    NSString *html = @"<mx-reply><blockquote><a href=\"https://matrix.to/#/someroom/someevent\">In reply to</a> <a href=\"https://matrix.to/#/@alice:matrix.org\">@alice:matrix.org</a><br>Original message.</blockquote></mx-reply>This is a reply.";
    
    // When rendering this string as an attributed string.
    NSAttributedString *attributedString = [eventFormatter renderHTMLString:html
                                                                   forEvent:anEvent
                                                              withRoomState:nil
                                                         andLatestRoomState:nil];
    
    // Then the attributed string should contain all of the text,
    NSString *plainString = [attributedString.string stringByReplacingOccurrencesOfString:@"\U00002028" withString:@"\n"];
    XCTAssertEqualObjects(plainString, @"In reply to @alice:matrix.org\nOriginal message.\nThis is a reply.",
                          @"The reply string should include who the original message was from, what they said, and the reply itself.");
    
    // and format the author and original message inside of a quotation block.
    __block BOOL didTestReplyText = NO;
    __block BOOL didTestQuoteBlock = NO;
    [attributedString enumerateAttributesInRange:NSMakeRange(0, attributedString.length)
                                         options:0
                                      usingBlock:^(NSDictionary<NSAttributedStringKey,id> * _Nonnull attributes, NSRange range, BOOL * _Nonnull stop) {
        NSString *substring = [attributedString attributedSubstringFromRange:range].string;
        
        if ([substring isEqualToString:@"This is a reply."])
        {
            XCTAssertNil(attributes[DTTextBlocksAttribute], @"The reply text should not appear within a block");
            didTestReplyText = YES;
        }
        else
        {
            XCTAssertNotNil(attributes[DTTextBlocksAttribute], @"The rest of the string should be within a block");
            didTestQuoteBlock = YES;
        }
    }];
    
    XCTAssertTrue(didTestReplyText && didTestQuoteBlock, @"Both a quote and a reply should be in the attributed string.");
}

- (void)testRenderHTMLStringWithMXReplyQuotingInvalidMessage
{
    // Given an HTML string representing a matrix reply where the original message has invalid HTML.
    NSString *html = @"<mx-reply><blockquote><a href=\"https://matrix.to/#/someroom/someevent\">In reply to</a> <a href=\"https://matrix.to/#/@alice:matrix.org\">@alice:matrix.org</a><br><h1>Heading with <badtag>invalid</badtag> content</h1></blockquote></mx-reply>This is a reply.";
    
    // When rendering this string as an attributed string.
    NSAttributedString *attributedString = [eventFormatter renderHTMLString:html
                                                                   forEvent:anEvent
                                                              withRoomState:nil
                                                         andLatestRoomState:nil];
    
    // Then the attributed string should contain all of the text,
    NSString *plainString = [attributedString.string stringByReplacingOccurrencesOfString:@"\U00002028" withString:@"\n"];
    XCTAssertEqualObjects(plainString, @"In reply to @alice:matrix.org\nHeading with invalid content\nThis is a reply.",
                          @"The reply string should include who the original message was from, what they said, and the reply itself.");
    
    // and format the author and original message inside of a quotation block. This check
    // is to catch any incorrectness in the sanitizing where the original message becomes
    // indented but is missing the block quote mark attribute.
    __block BOOL didTestReplyText = NO;
    __block BOOL didTestQuoteBlock = NO;
    [attributedString enumerateAttributesInRange:NSMakeRange(0, attributedString.length)
                                         options:0
                                      usingBlock:^(NSDictionary<NSAttributedStringKey,id> * _Nonnull attributes, NSRange range, BOOL * _Nonnull stop) {
        
        NSString *substring = [attributedString attributedSubstringFromRange:range].string;
        
        if ([substring isEqualToString:@"This is a reply."])
        {
            XCTAssertNil(attributes[DTTextBlocksAttribute], @"The reply text should not appear within a block");
            didTestReplyText = YES;
        }
        else
        {
            XCTAssertNotNil(attributes[DTTextBlocksAttribute], @"The rest of the string should be within a block");
            XCTAssertNotNil(attributes[kMXKToolsBlockquoteMarkAttribute], @"The block should have the blockquote style applied");
            didTestQuoteBlock = YES;
        }
    }];
    
    XCTAssertTrue(didTestReplyText && didTestQuoteBlock, @"Both a quote and a reply should be in the attributed string.");
}

- (void)testRenderHTMLStringWithImageHandler
{
    MXWeakify(self);
    
    // Given an HTML string that contains an image tag inline.
    NSURL *imageURL = [NSURL URLWithString:@"https://matrix.org/images/matrix-logo.svg"];
    NSString *html = [NSString stringWithFormat:@"Look at this logo: <img src=\"%@\"> Very nice.", imageURL.absoluteString];
    
    // When rendering this string as an attributed string using an appropriate image handler block.
    eventFormatter.allowedHTMLTags = [eventFormatter.allowedHTMLTags arrayByAddingObject:@"img"];
    eventFormatter.htmlImageHandler = ^NSURL *(NSString *sourceURL, CGFloat width, CGFloat height) {
        MXStrongifyAndReturnValueIfNil(self, nil);
        
        // Replace the image URL with one from the tests bundle
        NSBundle *bundle = [NSBundle bundleForClass:self.class];;
        return [bundle URLForResource:@"test" withExtension:@"png"];
    };
    NSAttributedString *attributedString = [eventFormatter renderHTMLString:html
                                                                   forEvent:anEvent
                                                              withRoomState:nil
                                                         andLatestRoomState:nil];
    
    // Then the attributed string should contain all of the text,
    NSString *plainString = [attributedString.string stringByReplacingOccurrencesOfString:@"\U0000fffc" withString:@""];
    XCTAssertEqualObjects(plainString, @"Look at this logo:  Very nice.", @"The string should include the original text.");
    
    // and have the image included as an attachment.
    __block BOOL hasImageAttachment = NO;
    [attributedString enumerateAttribute:NSAttachmentAttributeName
                                 inRange:NSMakeRange(0, attributedString.length)
                                 options:0
                              usingBlock:^(id value, NSRange range, BOOL *stop) {
        if ([value image])
        {
            hasImageAttachment = YES;
        }
    }];
    
    XCTAssertTrue(hasImageAttachment, @"There should be an attachment that contains the image.");
}
    
- (void)testMarkdownFormatting
{
    NSString *html = [eventFormatter htmlStringFromMarkdownString:@"Line One.\nLine Two."];
    
    BOOL hardBreakExists =      [html rangeOfString:@"<br />"].location != NSNotFound;
    BOOL openParagraphExists =  [html rangeOfString:@"<p>"].location != NSNotFound;
    BOOL closeParagraphExists = [html rangeOfString:@"</p>"].location != NSNotFound;
    
    // Check for some known error cases
    XCTAssert(hardBreakExists, "The soft break (\\n) must be converted to a hard break (<br />).");
    XCTAssert(!openParagraphExists && !closeParagraphExists, "The html must not contain any opening or closing paragraph tags.");
}

#pragma mark - Links

- (void)testRoomAliasLink
{
    NSString *s = @"Matrix HQ room is at #matrix:matrix.org.";
    NSAttributedString *as = [eventFormatter renderString:s forEvent:anEvent];

    NSRange linkRange = [s rangeOfString:@"#matrix:matrix.org"];

    __block NSUInteger ranges = 0;
    __block BOOL linkCreated = NO;

    [as enumerateAttributesInRange:NSMakeRange(0, as.length) options:(0) usingBlock:^(NSDictionary<NSString *,id> * _Nonnull attrs, NSRange range, BOOL * _Nonnull stop) {

        ranges++;

        if (NSEqualRanges(linkRange, range))
        {
            linkCreated = (attrs[NSLinkAttributeName] != nil);
        }
    }];

    XCTAssertEqual(ranges, 3, @"A sub-component must have been found");
    XCTAssert(linkCreated, @"Link not created as expected: %@", as);
}

- (void)testLinkWithRoomAliasLink
{
    NSString *s = @"Matrix HQ room is at https://matrix.to/#/room/#matrix:matrix.org.";
    NSAttributedString *as = [eventFormatter renderString:s forEvent:anEvent];

    __block NSUInteger ranges = 0;

    [as enumerateAttributesInRange:NSMakeRange(0, as.length) options:(0) usingBlock:^(NSDictionary<NSString *,id> * _Nonnull attrs, NSRange range, BOOL * _Nonnull stop) {

        ranges++;
    }];

    XCTAssertEqual(ranges, 1, @"There should be no link in this case. We let the UI manage the link");
}

#pragma mark - Event sender/target info

- (void)testUserDisplayNameFromEventContent {
    MXEvent *event = [self eventFromJSON:@"{\"sender\":\"@alice:matrix.org\",\"content\":{\"displayname\":\"bob\",\"membership\":\"invite\"},\"origin_server_ts\":1616488993287,\"state_key\":\"@bob:matrix.org\",\"room_id\":\"!foofoofoofoofoofoo:matrix.org\",\"event_id\":\"$lGK3budX5w009ErtQwE9ZFhwyUUAV9DqEN5yb2fI4Do\",\"type\":\"m.room.member\",\"unsigned\":{}}"];
    XCTAssertEqualObjects([eventFormatter userDisplayNameFromContentInEvent:event withMembershipFilter:nil], @"bob");
    XCTAssertEqualObjects([eventFormatter userDisplayNameFromContentInEvent:event withMembershipFilter:@"invite"], @"bob");
    XCTAssertEqualObjects([eventFormatter userDisplayNameFromContentInEvent:event withMembershipFilter:@"join"], nil);
}

- (void)testUserDisplayNameFromNonMembershipEventContent {
    MXEvent *event = [self eventFromJSON:@"{\"sender\":\"@alice:matrix.org\",\"content\":{\"ciphertext\":\"foo\",\"sender_key\":\"bar\",\"device_id\":\"foobar\",\"algorithm\":\"m.megolm.v1.aes-sha2\"}},\"origin_server_ts\":1616488993287,\"state_key\":\"@bob:matrix.org\",\"room_id\":\"!foofoofoofoofoofoo:matrix.org\",\"event_id\":\"$lGK3budX5w009ErtQwE9ZFhwyUUAV9DqEN5yb2fI4Do\",\"type\":\"m.room.encrypted\",\"unsigned\":{}}"];
    XCTAssertEqualObjects([eventFormatter userDisplayNameFromContentInEvent:event withMembershipFilter:nil], nil);
    XCTAssertEqualObjects([eventFormatter userDisplayNameFromContentInEvent:event withMembershipFilter:@"join"], nil);
}

- (void)testUserAvatarUrlFromEventContent {
    MXEvent *event = [self eventFromJSON:@"{\"sender\":\"@alice:matrix.org\",\"content\":{\"displayname\":\"bob\",\"avatar_url\":\"mxc://foo.bar\",\"membership\":\"join\"},\"origin_server_ts\":1616488993287,\"state_key\":\"@bob:matrix.org\",\"room_id\":\"!foofoofoofoofoofoo:matrix.org\",\"event_id\":\"$lGK3budX5w009ErtQwE9ZFhwyUUAV9DqEN5yb2fI4Do\",\"type\":\"m.room.member\",\"unsigned\":{}}"];
    XCTAssertEqualObjects([eventFormatter userAvatarUrlFromContentInEvent:event withMembershipFilter:nil], @"mxc://foo.bar");
    XCTAssertEqualObjects([eventFormatter userAvatarUrlFromContentInEvent:event withMembershipFilter:@"invite"], nil);
    XCTAssertEqualObjects([eventFormatter userAvatarUrlFromContentInEvent:event withMembershipFilter:@"join"], @"mxc://foo.bar");
}

- (void)testUserAvatarUrlFromEventWithNonMXCAvatarUrlContent {
    MXEvent *event = [self eventFromJSON:@"{\"sender\":\"@alice:matrix.org\",\"content\":{\"displayname\":\"bob\",\"avatar_url\":\"http://foo.bar\",\"membership\":\"join\"},\"origin_server_ts\":1616488993287,\"state_key\":\"@bob:matrix.org\",\"room_id\":\"!foofoofoofoofoofoo:matrix.org\",\"event_id\":\"$lGK3budX5w009ErtQwE9ZFhwyUUAV9DqEN5yb2fI4Do\",\"type\":\"m.room.member\",\"unsigned\":{}}"];
    XCTAssertEqualObjects([eventFormatter userAvatarUrlFromContentInEvent:event withMembershipFilter:nil], nil);
    XCTAssertEqualObjects([eventFormatter userAvatarUrlFromContentInEvent:event withMembershipFilter:@"invite"], nil);
    XCTAssertEqualObjects([eventFormatter userAvatarUrlFromContentInEvent:event withMembershipFilter:@"join"], nil);
}

- (void)testUserAvatarUrlFromNonMembershipEventContent {
    MXEvent *event = [self eventFromJSON:@"{\"sender\":\"@alice:matrix.org\",\"content\":{\"ciphertext\":\"foo\",\"sender_key\":\"bar\",\"device_id\":\"foobar\",\"algorithm\":\"m.megolm.v1.aes-sha2\"}},\"origin_server_ts\":1616488993287,\"state_key\":\"@bob:matrix.org\",\"room_id\":\"!foofoofoofoofoofoo:matrix.org\",\"event_id\":\"$lGK3budX5w009ErtQwE9ZFhwyUUAV9DqEN5yb2fI4Do\",\"type\":\"m.room.encrypted\",\"unsigned\":{}}"];
    XCTAssertEqualObjects([eventFormatter userAvatarUrlFromContentInEvent:event withMembershipFilter:nil], nil);
    XCTAssertEqualObjects([eventFormatter userAvatarUrlFromContentInEvent:event withMembershipFilter:@"join"], nil);
}

- (MXEvent *)eventFromJSON:(NSString *)json {
    NSData *data = [json dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
    return [MXEvent modelFromJSON:dict];
}

@end
