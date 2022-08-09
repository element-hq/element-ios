# Customisation

This guide contains information about how to configure and customise the project for forks.

## Project

The bundle identifier, app group identifier and app name are defined in the `Config/AppIdentifiers.xcconfig` file and advanced build configuration can be found in the `project.yml` file and each target has a `target.yml` file in its respective folder.

## Build Settings

Various features of Element iOS can be enabled/disabled/configured via flags in the `Config/BuildSettings.swift` file. This includes items such as the default homeserver, VoIP configuration and the ability to hide certain settings from the user.

## Theme

Element iOS has a [dependency](https://github.com/vector-im/element-ios/blob/92fc7046ede2720d4b46bffd07d97ce59b50d95f/project.yml#L42-L44) on our DesignKit package which supplies the fonts, colours and some common components we use across multiple apps. The fonts are defined [directly](https://github.com/vector-im/element-x-ios/tree/develop/DesignKit/Sources/Fonts) in this package. The colours come from a [dependency](https://github.com/vector-im/element-x-ios/blob/2f69c9978231b6e7cf0b0c3126846f2369e999bb/Package.swift#L13) on our [Design Tokens](https://github.com/vector-im/element-design-tokens) repo which is a style dictionary that allows to us share definitions across multiple platforms.

For logos, they're currently regular assets that can be found either in [Images.xcassets](https://github.com/vector-im/element-ios/tree/develop/Riot/Assets/Images.xcassets) or [SharedImages.xcassets](https://github.com/vector-im/element-ios/tree/develop/Riot/Assets/SharedImages.xcassets).
