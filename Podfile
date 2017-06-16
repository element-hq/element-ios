# Uncomment this line to define a global platform for your project
platform :ios, "8.0"

source 'https://github.com/CocoaPods/Specs.git'

target "Riot" do


# Different flavours of pods to MatrixKit
# The tagged version on which this version of Riot has been built
pod 'MatrixKit', '0.5.0'

# The lastest release available on the CocoaPods repository 
#pod 'MatrixKit'

# The develop branch version
#pod 'MatrixSDK', :git => 'https://github.com/matrix-org/matrix-ios-sdk.git', :branch => 'develop'
#pod 'MatrixKit', :git => 'https://github.com/matrix-org/matrix-ios-kit.git', :branch => 'develop'

# The one used for developing both MatrixSDK and MatrixKit
# Note that MatrixSDK must be cloned into a folder called matrix-ios-sdk next to the MatrixKit folder
#pod 'MatrixKit', :path => '../matrix-ios-kit/MatrixKit.podspec'
#pod 'MatrixSDK', :path => '../matrix-ios-sdk/MatrixSDK.podspec'

pod 'GBDeviceInfo', '~> 4.3.0'

pod 'GoogleAnalytics'

# The Google WebRTC stack
pod 'WebRTC', '58.17.16937'

# OLMKit for crypto
pod 'OLMKit'
#pod 'OLMKit', :path => '../olm/OLMKit.podspec'
pod 'Realm', '~> 2.8.1'

# Remove warnings from "bad" pods
pod 'OLMKit', :inhibit_warnings => true
pod 'cmark', :inhibit_warnings => true
pod 'DTCoreText', :inhibit_warnings => true

end

