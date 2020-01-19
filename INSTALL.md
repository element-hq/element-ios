# Installation

## Install build tools

To build Riot iOS project you need:

- Xcode 10.3, if you have a newer Xcode version on your Mac you can download it from the Apple Developer Portal [here](https://download.developer.apple.com/Developer_Tools/Xcode_10.3/Xcode_10.3.xip).
- [cmake](https://gitlab.kitware.com/cmake/cmake), used to build [OMLKit](https://gitlab.matrix.org/matrix-org/olm/tree/master/xcode) dependency.
- [CocoaPods](https://cocoapods.org) 1.8.4. Manages library dependencies for Xcode projects.
- [bundler](https://bundler.io/) (optional), is also a dependency manager used to manage build tools dependency (CocoaPods, Fastlane)

### Install cmake

You can install cmake using [Homebrew](http://brew.sh/):

```
brew install cmake
```

### Install CocoaPods

If you want to install CocoaPods into your user directory and using it in sudo-less mode you can read this official guide [here](https://guides.cocoapods.org/using/getting-started.html#sudo-less-installation).

```
gem install cocoapods
```

### Install bundler (optional)

```
gem install bundler
```

## Choose what to build

To choose the version you want to develop and build against you will have to modify the right definitions of `$matrixKitVersion` variable in the `Podfile`. 

### Determine your needs

To select which `$matrixKitVersion` value to use you have to determine your needs:

- **Build an App Store release version**

To build the last published App Store code you just need to checkout master branch. If you want to build an older App Store version just checkout the tag of the corresponding version. You have nothing to modify in the `Podfile`. In this case `$matrixKitVersion` will be set to a specific version of MatrixKit already published on CocoaPods repositoy.

- **Build last development code and modify Riot project only**

If you want to build last developpement code you have to checkout the develop branch and uncomment `$matrixKitVersion = 'develop'` in the `Podfile`. This will also use MatrixKit and MatrixSDK develop branches.

- **Build any branch and be able to modify MatrixKit and MatrixSDK locally**

If you want to modify MatrixKit and/or MatrixSDK locally and see the result in Riot project you have uncommment `$matrixKitVersion = 'local'` in the `Podfile`.
But before you have to checkout [MatrixKit](https://github.com/matrix-org/matrix-ios-kit) repository in `../matrix-ios-kit` and [MatrixSDK](https://github.com/matrix-org/matrix-ios-sdk) in `../matrix-ios-sdk` locally relatively to your Riot iOS project folder.
Be sure to use compatible branches for Riot iOS, MatrixKit and MatrixSDK. For example if you want to modify Riot iOS from develop branch use MatrixKit and MatrixSDK develop branches and then make your modifications.

**Important**: By working with local pods (development pods) you will need to use legacy build system in Xcode to have your local changes taken into account. To enable it go to Xcode menu and select `File > Workspace Settings… > Build System` and then choose `Legacy Build System`.

### Modify `$matrixKitVersion` after installation of dependencies

Assuming you have already completed the **Install dependencies** instructions from **Build** section below.

Each time you edit `$matrixKitVersion` variable in the `Podfile` you will have to run the `pod install` command.

## Build

### Install dependencies

Before opening the Riot Xcode workspace, you need to install dependencies via CocoaPods.

To be sure to use the right CocoaPods version you can use `bundler`:

```
$ cd Riot
$ bundle install
$ bundle exec pod install
```

Or if you prefer to use directly CocoaPods:

```
$ cd Riot
$ pod install
```

This will load all dependencies for the Riot source code, including [MatrixKit](https://github.com/matrix-org/matrix-ios-kit) 
and [MatrixSDK](https://github.com/matrix-org/matrix-ios-sdk). 

### Open workspace

Then, open `Riot.xcworkspace` with Xcode.

```
$ open Riot.xcworkspace
```

**Note**: If you have multiple Xcode versions installed don't forget to use the right version of Command Line Tools when you are building the app. To check the Command Line Tools version go to `Xcode > Preferences > Locations > Command Line Tools` and check that the displayed version match your Xcode version.


### Configure project

You may need to change the bundle identifier and app group identifier to be unique to get Xcode to build the app. Make sure to change the application group identifier everywhere by running a search for `group.im.vector` and changing every spot that identifier is used to your new identifier.
