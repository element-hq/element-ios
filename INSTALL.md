# Installation

## Install build tools

To build Element iOS project you need:

- Xcode 12.1+.
- [Ruby](https://www.ruby-lang.org/), a dynamic programming language used by several build tools.
- [CocoaPods](https://cocoapods.org), library dependencies manager for Xcode projects.
- [XcodeGen](https://github.com/yonaskolb/XcodeGen), an Xcode project generator.
- [Mint](https://github.com/yonaskolb/Mint), a package manager that installs and runs executable Swift packages
- [bundler](https://bundler.io/) (optional), is also a dependency manager used to manage build tools dependency (CocoaPods, Fastlane).

### Install Ruby

Ruby is required for several build tools like CocoaPods, bundler and fastlane. Ruby is preinstalled on macOS, the system version is sufficient to build the project tools, it's not required to install the latest version. If you want to install the lastest version of Ruby please check [official instructions](https://www.ruby-lang.org/en/documentation/installation/#homebrew).

If you do not want to grant the ruby package manager, [RubyGems](https://rubygems.org/), admin privileges and you prefer install gems into your user directory, you can read instructions from the CocoaPods [guide about sudo-less installation](https://guides.cocoapods.org/using/getting-started.html#sudo-less-installation).

### Install CocoaPods

To install CocoaPods you can grab the right version by using `bundler` (recommended) or you can directly install it with RubyGems:

```
$ gem install cocoapods
```

In the last case please ensure that you are using the same version as indicated at the end of the `Podfile.lock` file.

### Install XcodeGen and Mint

You can install XcodeGen and Mint using the included [Homebrew](https://brew.sh) Brewfile:

```
$ brew bundle
```

### Install bundler (optional)

By using `bundler` you will ensure to use the right versions of build tools used to build and deliver the project. You can find dependency definitions in the `Gemfile`. To install `bundler`:

```
$ gem install bundler
```

## Choose Matrix SDKs version to build

To choose the [MatrixSDK](https://github.com/matrix-org/matrix-ios-sdk) version (and depending OLMKit) you want to develop and build against you will have to modify the right definitions of `$matrixSDKVersion` variable in the `Podfile`. 

### Determine your needs

To select which `$matrixSDKVersion` value to use you have to determine your needs:

- **Build an App Store release version**

To build the last published App Store code you just need to checkout master branch. If you want to build an older App Store version just checkout the tag of the corresponding version. You have nothing to modify in the `Podfile`. In this case `$matrixSDKVersion` will be set to a specific version of the MatrixSDK already published on CocoaPods repository.

- **Build last development code and modify Element project only**

If you want to build last development code you have to checkout the `develop` branch and use `$matrixSDKVersion = {:branch => 'develop'}` in the `Podfile`. This will also use MatrixSDK develop branch.

- **Build specific branch of SDK and modify Element project only**

If you want to build a specific branch for the MatrixSDK you have to indicate it using a dictionary like this: `$matrixSDKVersion = {:branch => 'sdk_branch_name'}`.

- **Build any branch and be able to modify MatrixSDK locally**

If you want to modify MatrixSDK locally and see the result in Element project you have to uncommment `$matrixSDKVersion = :local` in the `Podfile`.
But before you have to checkout [MatrixSDK](https://github.com/matrix-org/matrix-ios-sdk) in `../matrix-ios-sdk` locally relatively to your Element iOS project folder.
Be sure to use compatible branches for Element iOS and MatrixSDK. For example, if you want to modify Element iOS from develop branch, use MatrixSDK develop branch and then make your modifications.

**Important**: By working with [XcodeGen](https://github.com/yonaskolb/XcodeGen) you will need to use the _New Build System_ in Xcode, to have your some of the xcconfig variables taken into account. It should be enabled by default on the latest Xcode versions, but if you need to enable it go to Xcode menu and select `File > Workspace Settings… > Build System` and then choose `New Build System`.

- **Running a local rust MatrixCryptoSDK locally**

If you want to debug locally or test local changes of the rust `MatrixSDKCrypto` with a local `MatrixSDK`, you must checkout [matrix-rust-sdk](https://github.com/matrix-org/matrix-rust-sdk), and follow the [instructions in the repository](https://github.com/matrix-org/matrix-rust-sdk/tree/main/bindings/apple).

Once the framework is built using `./build_crypto_xcframework.sh` you will have to move `bindings/apple/MatrixSDKCrypto-Local.podspec` to the root of the `matrix-rust-sdk` folder and rename it to `MatrixSDKCrypto.podspec` then update `s.version` with the current pod version:

```
    s.version               = "0.3.12"
```

Then in the element-ios `Podfile`, add the following line under the existing `pod 'MatrixSDK' [..]`:

```
pod 'MatrixSDKCrypto', :path => '../matrix-rust-sdk/MatrixSDKCrypto.podspec'
```

Run `pod install` to refresh all.


### `$matrixSDKVersion` Modification

Every time you change the `$matrixSDKVersion` variable in the `Podfile`, you have to run the `pod install` command again.


## Build

### Configure project

You may need to change the bundle identifier and app group identifier to be unique to get Xcode to build the app. Make sure to change the bundle identifier, application group identifier and app name in the `Config/AppIdentifiers.xcconfig` file to your new identifiers.

More advanced build configuration can be found in the `project.yml` file and each target has a `target.yml` file in its respective folder.


### Generate Xcode project

In order to get rid of git conflicts, the `Riot.xcodeproj` is not pushed into the git repository anymore but generated using `XcodeGen`. To generate the `xcodeproj` file simply run the following command line from the root folder :

```
$ xcodegen
```


### Install dependencies

Then, before opening the Element Xcode workspace, you need to install dependencies via CocoaPods.

To be sure to use the right CocoaPods version you can use `bundler`:

```
$ bundle install
$ bundle exec pod install
```

Or if you prefer to use directly CocoaPods:

```
$ pod install
```

This will load all dependencies for the Element source code, including [MatrixSDK](https://github.com/matrix-org/matrix-ios-sdk).


### Open workspace

Then, open `Riot.xcworkspace` with Xcode.

```
$ open Riot.xcworkspace
```

**Note**: If you have multiple Xcode versions installed don't forget to use the right version of Command Line Tools when you are building the app. To check the Command Line Tools version go to `Xcode > Preferences > Locations > Command Line Tools` and check that the displayed version match your Xcode version.


### Generate the project in one line without effort

If you want to generate the project easily and quickly, there is a local script called `setup_project.sh` that creates the `xcodeproj` and `xcworkspace` with all source files and dependencies with commands described before. It automatically selects the right dependencies based on your local Git branch or your Podfile local modifications. All you have to do is to go in the project root folder and run the script:

```
$ ./setup_project.sh
```

## Generate IPA

To build the IPA we are currently using [fastlane](https://fastlane.tools/).

**Set your project informations**

Before making the release you need to modify the `fastlane/.env.default` file and set all your project informations like your App ID, Team ID, certificate names and so on.

**Install or update build tools**

The preferred way to use the fastlane script is to use `bundler`, to be sure to use the right dependency versions.

After opening the terminal in the project root folder. The first time you perform a release you need to run:

`bundle install`

For other times:

`bundle update`

**Run fastlane script**

Before executing the release command you need to export your Apple ID in environment variables:

`export APPLE_ID="foo.bar@apple.com"`

To make an App Store release you can directly execute this command:

`bundle exec fastlane app_store build_number:<your_build_number>`

Or you can use the wrapper script located at `/Tools/Release/buildRelease.sh`. For that go to the `Release` folder: 

`$ cd ./Tools/Release/`

And then indicate a branch or a tag like this:

`$ ./buildRelease.sh <tag or branch>`
