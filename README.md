# Element iOS

![GitHub release (latest by date)](https://img.shields.io/github/v/release/element-hq/element-ios)
![badge-languages](https://img.shields.io/badge/languages-Swift%20%7C%20ObjC-orange.svg)
[![Swift 5.x](https://img.shields.io/badge/Swift-5.x-orange)](https://developer.apple.com/swift)
[![Build status](https://badge.buildkite.com/cc8f93e32da93fa7c1172398bd8af66254490567c7195a5f3f.svg?branch=develop)](https://buildkite.com/matrix-dot-org/element-ios/builds?branch=develop)
[![Weblate](https://translate.riot.im/widgets/riot-ios/-/svg-badge.svg)](https://translate.riot.im/engage/riot-ios/?utm_source=widget)
[![codecov](https://codecov.io/gh/element-hq/element-ios/branch/develop/graph/badge.svg?token=INNm5o6XWg)](https://codecov.io/gh/element-hq/element-ios)
[![Quality Gate Status](https://sonarcloud.io/api/project_badges/measure?project=element-ios&metric=alert_status)](https://sonarcloud.io/summary/new_code?id=element-ios)
[![Bugs](https://sonarcloud.io/api/project_badges/measure?project=element-ios&metric=bugs)](https://sonarcloud.io/summary/new_code?id=element-ios)
[![Vulnerabilities](https://sonarcloud.io/api/project_badges/measure?project=element-ios&metric=vulnerabilities)](https://sonarcloud.io/summary/new_code?id=element-ios)
[![Element iOS Matrix room #element-ios:matrix.org](https://img.shields.io/matrix/element-ios:matrix.org.svg?label=%23element-ios:matrix.org&logo=matrix&server_fqdn=matrix.org)](https://matrix.to/#/#element-ios:matrix.org)
![GitHub](https://img.shields.io/github/license/element-hq/element-ios)
[![Twitter URL](https://img.shields.io/twitter/url?label=Element&url=https%3A%2F%2Ftwitter.com%2Felement_hq)](https://twitter.com/element_hq)

Element iOS is an iOS [Matrix](https://matrix.org/) client provided by [Element](https://element.io/). It is based on [MatrixSDK](https://github.com/matrix-org/matrix-ios-sdk).

<p align="center">  
  <a href=https://itunes.apple.com/us/app/element/id1083446067?mt=8>
  <img alt="Download on the app store" src="https://www.apple.com/lae/itunes/link/images/link_badge_appstore_large_2x.png" width=160>
  </a>
</p>

## Beta testing 

You can try last beta build by accessing our [TestFlight Public Link](https://testflight.apple.com/join/lCeTuDKM). For questions and feedback about latest TestFlight build, please access the Element iOS Matrix room: [#element-ios:matrix.org](https://matrix.to/#/#element-ios:matrix.org).

## Build instructions

If you have already everything installed, opening the project workspace in Xcode should be as easy as:

```
$ xcodegen                  # Create the xcodeproj with all project source files
$ pod install               # Create the xcworkspace with all project dependencies
$ open Riot.xcworkspace     # Open Xcode
```

Else, you can visit our [installation guide](./INSTALL.md). This guide also offers more details and advanced usage like using [MatrixSDK](https://github.com/matrix-org/matrix-ios-sdk) in its development version.

## Contributing

If you want to contribute to Element iOS code or translations, go to the [contribution guide](CONTRIBUTING.md).

## Support

When you are experiencing an issue on Element iOS, please first search in [GitHub issues](https://github.com/element-hq/element-ios/issues)
and then in [#element-ios:matrix.org](https://matrix.to/#/#element-ios:matrix.org).
If after your research you still have a question, ask at [#element-ios:matrix.org](https://matrix.to/#/#element-ios:matrix.org). Otherwise feel free to create a GitHub issue if you encounter a bug or a crash, by explaining clearly in detail what happened. You can also perform bug reporting (Rageshake) from the Element application by shaking your phone or going to the application settings. This is especially recommended when you encounter a crash.

## Copyright & License

Copyright (c) 2014-2017 OpenMarket Ltd  
Copyright (c) 2017 Vector Creations Ltd  
Copyright (c) 2017-2025 New Vector Ltd

This software is dual licensed by New Vector Ltd (Element). It can be used either:

(1) for free under the terms of the GNU Affero General Public License (as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version); OR

(2) under the terms of a paid-for Element Commercial License agreement between you and Element (the terms of which may vary depending on what you and Element have agreed to).

Unless required by applicable law or agreed to in writing, software distributed under the Licenses is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the Licenses for the specific language governing permissions and limitations under the Licenses.
