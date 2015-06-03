# Uncomment this line to define a global platform for your project
# platform :ios, "6.0"

source 'https://github.com/CocoaPods/Specs.git'

target "matrixConsole" do


# Different flavours of pods to MatrixKit
# The tagged version on which this version of Console has been built
#pod 'MatrixKit', '~> 0.1.0'

# The lastest release available on the CocoaPods repository 
#pod 'MatrixKit'

# The develop branch version
pod 'MatrixSDK', :git => 'https://github.com/matrix-org/matrix-ios-sdk.git', :branch => 'develop'
pod 'MatrixKit', :git => 'https://github.com/matrix-org/matrix-ios-kit.git', :branch => 'develop'

# The one used for developping both MatrixSDK and MatrixKit
# Note that MatrixSDK must be cloned into a folder called matrix-ios-sdk next to the MatrixKit folder
#pod 'MatrixKit', :path => '../matrix-ios-kit/MatrixKit.podspec'
#pod 'MatrixSDK', :path => '../matrix-ios-sdk/MatrixSDK.podspec'


pod 'libPhoneNumber-iOS', '~> 0.7.6'
pod 'GBDeviceInfo', '~> 2.2.9'

# There is no pod for OpenWebRTC-SDK. Use the master branch from github
# As of 2015/05/06, it works
#pod 'OpenWebRTC-SDK', :git => 'https://github.com/EricssonResearch/openwebrtc-ios-sdk.git', :branch => 'master'

# Matrix.org fork of 'OpenWebRTC-SDK'
#pod 'OpenWebRTC-SDK', :path => '../openwebrtc-ios-sdk-mx/OpenWebRTC-SDK.podspec'
pod 'OpenWebRTC-SDK', :git => 'https://github.com/matrix-org/openwebrtc-ios-sdk.git', :branch => 'cvo_support'

end

target "matrixConsole" do

end

