# Customisation

This guide contains information about how to configure and customise the project for forks.

## Project

The bundle identifier, app group identifier and app name are defined in the `Config/AppIdentifiers.xcconfig` file and advanced build configuration can be found in the `project.yml` file and each target has a `target.yml` file in its respective folder.

## Build Settings

Various features of Element iOS can be enabled/disabled/configured via flags in the `Config/BuildSettings.swift` file. This includes items such as the default homeserver, VoIP configuration and the ability to hide certain settings from the user.

## Theme

The themes used in Element iOS can be found in `Riot/Managers/Theme/Themes`. A newer theming system is available as nested `colors` and `fonts` properties on these themes and can be found in `DesignKit/Variants/Colors` and `DesignKit/Variants/Fonts` respectively. The newer system is used for screens built in UIKit with Swift and all of the SwiftUI screens.

For logos, they're currently regular assets that can be found either in [Images.xcassets](https://github.com/vector-im/element-ios/tree/develop/Riot/Assets/Images.xcassets) or [SharedImages.xcassets](https://github.com/vector-im/element-ios/tree/develop/Riot/Assets/SharedImages.xcassets).
