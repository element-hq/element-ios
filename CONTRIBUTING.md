# Contributing code to Matrix

Please read the matrix-ios-sdk [contributing guide](https://github.com/matrix-org/matrix-ios-sdk/blob/develop/CONTRIBUTING.md).

# Contributing code to Element iOS

## I want to help translating

If you want to fix an issue for an English string, please submit a pull request to the Element iOS GitHub repository.
If you want to fix an issue for another language, add a missing translation, or  add a new language, please read [Element Web translating guide](https://github.com/vector-im/element-web/blob/develop/docs/translating.md) first and then use the Element iOS [Weblate](https://translate.riot.im/projects/riot-ios/).

If you have any question regarding translations please ask in [Element Translation room](https://matrix.to/#/#element-translations:matrix.org).

## Setting up a development environment

Please refer to the [installation guide](INSTALL.md) to setup the project.

## Implement a new screen or new screen flow

New screen flows are currently using MVVM-Coordinator pattern. Please refer to the screen template [Readme](Tools/Templates/README.md) to create a new screen or a new screen flow.

## Coding style

For Swift coding style we use [SwiftLint](https://github.com/realm/SwiftLint) to check some conventions at compile time (rules are located in the `.swiftlint.yml` file). 
Otherwise please have a look to [Apple Swift conventions](https://swift.org/documentation/api-design-guidelines.html#conventions). We are also using some of the conventions of [raywenderlich.com Swift style guide](https://github.com/raywenderlich/swift-style-guide).

## Pull request

When you are making a pull request please read carefully the [Pull Request Checklist](https://github.com/vector-im/element-ios/blob/develop/.github/PULL_REQUEST_TEMPLATE.md).

## Thanks

Thanks for contributing to Matrix projects!