// 
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import XCTest

@testable import Element

final class MarkdownToHTMLRendererTests: XCTestCase {
    // MARK: - Tests
    /// Test autolinks HTML render.
    func testRenderAutolinks() {
        let input = [
            "Test1:",
            "<#_foonetic_xkcd:matrix.org>",
            "<http://google.com/_thing_>",
            "<https://matrix.org/_matrix/client/foo/123_>",
            "<#_foonetic_xkcd:matrix.org>",
            "",
            "Test1A:",
            "<#_foonetic_xkcd:matrix.org>",
            "<http://google.com/_thing_>",
            "<https://matrix.org/_matrix/client/foo/123_>",
            "<#_foonetic_xkcd:matrix.org>",
            "",
            "Test2:",
            "<http://domain.xyz/foo/bar-_stuff-like-this_-in-it.jpg>",
            "<http://domain.xyz/foo/bar-_stuff-like-this_-in-it.jpg>",
            "",
            "Test3:",
            "<https://riot.im/app/#/room/#_foonetic_xkcd:matrix.org>",
            "<https://riot.im/app/#/room/#_foonetic_xkcd:matrix.org>",
        ].joined(separator: "\n")
        let expectedOutput = [
            "<p>Test1:\n&lt;#_foonetic_xkcd:matrix.org&gt;\n<a href=\"http://google.com/_thing_\">http://google.com/_thing_</a>\n<a href=\"https://matrix.org/_matrix/client/foo/123_\">https://matrix.org/_matrix/client/foo/123_</a>\n&lt;#_foonetic_xkcd:matrix.org&gt;</p>",
            "<p>Test1A:\n&lt;#_foonetic_xkcd:matrix.org&gt;\n<a href=\"http://google.com/_thing_\">http://google.com/_thing_</a>\n<a href=\"https://matrix.org/_matrix/client/foo/123_\">https://matrix.org/_matrix/client/foo/123_</a>\n&lt;#_foonetic_xkcd:matrix.org&gt;</p>",
            "<p>Test2:\n<a href=\"http://domain.xyz/foo/bar-_stuff-like-this_-in-it.jpg\">http://domain.xyz/foo/bar-_stuff-like-this_-in-it.jpg</a>\n<a href=\"http://domain.xyz/foo/bar-_stuff-like-this_-in-it.jpg\">http://domain.xyz/foo/bar-_stuff-like-this_-in-it.jpg</a></p>",
            "<p>Test3:\n<a href=\"https://riot.im/app/#/room/#_foonetic_xkcd:matrix.org\">https://riot.im/app/#/room/#_foonetic_xkcd:matrix.org</a>\n<a href=\"https://riot.im/app/#/room/#_foonetic_xkcd:matrix.org\">https://riot.im/app/#/room/#_foonetic_xkcd:matrix.org</a></p>",
            "",
        ].joined(separator: "\n")
        testRenderHTML(input: input, expectedOutput: expectedOutput)
    }

    /// Test links with markdown formatting conflict.
    func testRenderRepairedLinks() {
        let input = [
            "Test1:",
            "#_foonetic_xkcd:matrix.org",
            "http://google.com/_thing_",
            "https://matrix.org/_matrix/client/foo/123_",
            "#_foonetic_xkcd:matrix.org",
            "",
            "Test1A:",
            "#_foonetic_xkcd:matrix.org",
            "http://google.com/_thing_",
            "https://matrix.org/_matrix/client/foo/123_",
            "#_foonetic_xkcd:matrix.org",
            "",
            "Test2:",
            "http://domain.xyz/foo/bar-_stuff-like-this_-in-it.jpg",
            "http://domain.xyz/foo/bar-_stuff-like-this_-in-it.jpg",
            "",
            "Test3:",
            "https://riot.im/app/#/room/#_foonetic_xkcd:matrix.org",
            "https://riot.im/app/#/room/#_foonetic_xkcd:matrix.org",
        ].joined(separator: "\n")
        let expectedOutput = [
            "<p>Test1:\n#_foonetic_xkcd:matrix.org\nhttp://google.com/_thing_\nhttps://matrix.org/_matrix/client/foo/123_\n#_foonetic_xkcd:matrix.org</p>",
            "<p>Test1A:\n#_foonetic_xkcd:matrix.org\nhttp://google.com/_thing_\nhttps://matrix.org/_matrix/client/foo/123_\n#_foonetic_xkcd:matrix.org</p>",
            "<p>Test2:\nhttp://domain.xyz/foo/bar-_stuff-like-this_-in-it.jpg\nhttp://domain.xyz/foo/bar-_stuff-like-this_-in-it.jpg</p>",
            "<p>Test3:\nhttps://riot.im/app/#/room/#_foonetic_xkcd:matrix.org\nhttps://riot.im/app/#/room/#_foonetic_xkcd:matrix.org</p>",
            "",
        ].joined(separator: "\n")
        testRenderHTML(input: input, expectedOutput: expectedOutput)
    }

    /// Test links with markdown strong formatting conflict.
    func testRenderRepairedLinksWithStrongFormatting() {
        let input = "https://github.com/matrix-org/synapse/blob/develop/synapse/module_api/__init__.py"
        + " "
        + "https://github.com/matrix-org/synapse/blob/develop/synapse/module_api/__init__.py"
        let expectedOutput = "<p>https://github.com/matrix-org/synapse/blob/develop/synapse/module_api/__init__.py"
        + " "
        + "https://github.com/matrix-org/synapse/blob/develop/synapse/module_api/__init__.py</p>"
        + "\n"
        testRenderHTML(input: input, expectedOutput: expectedOutput)
    }

    /// Test links with markdown formatting conflict and actual markdown in between.
    func testRenderRepairedLinksWithMarkdownInBetween() {
        let input = "__Some bold text__ "
        + "https://github.com/matrix-org/synapse/blob/develop/synapse/module_api/__init__.py"
        + " _some emphased text_ "
        + "http://domain.xyz/foo/bar-_stuff-like-this_-in-it.jpg"
        let expectedOutput = "<p><strong>Some bold text</strong> "
        + "https://github.com/matrix-org/synapse/blob/develop/synapse/module_api/__init__.py"
        + " <em>some emphased text</em> "
        + "http://domain.xyz/foo/bar-_stuff-like-this_-in-it.jpg</p>"
        + "\n"
        testRenderHTML(input: input, expectedOutput: expectedOutput)
    }

    func testRenderRepairedLinksWithCharactersRequiringPercentEncoding() {
        let input = "Some link with special characters: "
        + "https://matrix.to/#/#_oftc_#matrix-dev:matrix.org"
        + " "
        + "https://matrix.to/#/#?=+-_#_"
        + "\n"
        let expectedOutput = "<p>Some link with special characters: "
        + "https://matrix.to/#/#_oftc_#matrix-dev:matrix.org"
        + " "
        + "https://matrix.to/#/#?=+-_#_</p>"
        + "\n"
        testRenderHTML(input: input, expectedOutput: expectedOutput)
    }

    /// Test links inside codeblocks.
    func testRenderLinksInCodeblock() {
        let input = "```"
        + [
            "Test1:",
            "#_foonetic_xkcd:matrix.org",
            "http://google.com/_thing_",
            "https://matrix.org/_matrix/client/foo/123_",
            "#_foonetic_xkcd:matrix.org",
            "",
            "Test1A:",
            "#_foonetic_xkcd:matrix.org",
            "http://google.com/_thing_",
            "https://matrix.org/_matrix/client/foo/123_",
            "#_foonetic_xkcd:matrix.org",
            "",
            "Test2:",
            "http://domain.xyz/foo/bar-_stuff-like-this_-in-it.jpg",
            "http://domain.xyz/foo/bar-_stuff-like-this_-in-it.jpg",
            "",
            "Test3:",
            "https://riot.im/app/#/room/#_foonetic_xkcd:matrix.org",
            "https://riot.im/app/#/room/#_foonetic_xkcd:matrix.org",
        ].joined(separator: "\n")
        + "```"
        let expectedOutput = [
            "<pre><code class=\"language-Test1:\">#_foonetic_xkcd:matrix.org",
            "http://google.com/_thing_",
            "https://matrix.org/_matrix/client/foo/123_",
            "#_foonetic_xkcd:matrix.org",
            "",
            "Test1A:",
            "#_foonetic_xkcd:matrix.org",
            "http://google.com/_thing_",
            "https://matrix.org/_matrix/client/foo/123_",
            "#_foonetic_xkcd:matrix.org",
            "",
            "Test2:",
            "http://domain.xyz/foo/bar-_stuff-like-this_-in-it.jpg",
            "http://domain.xyz/foo/bar-_stuff-like-this_-in-it.jpg",
            "",
            "Test3:",
            "https://riot.im/app/#/room/#_foonetic_xkcd:matrix.org",
            "https://riot.im/app/#/room/#_foonetic_xkcd:matrix.org```",
            "</code></pre>",
            "",
        ].joined(separator: "\n")
        testRenderHTML(input: input, expectedOutput: expectedOutput)
    }

    // MARK: - Private
    private func testRenderHTML(input: String, expectedOutput: String) {
        let output = MarkdownToHTMLRenderer().renderToHTML(markdown: input)
        XCTAssertEqual(output, expectedOutput)
    }
}
