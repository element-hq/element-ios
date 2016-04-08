# Uncomment this line to define a global platform for your project
# platform :ios, "7.0"

source 'https://github.com/CocoaPods/Specs.git'

target "Vector" do


# Different flavours of pods to MatrixKit
# The tagged version on which this version of Console has been built
#pod 'MatrixKit', '~> 0.3.5'

# The lastest release available on the CocoaPods repository 
#pod 'MatrixKit'

# The develop branch version
pod 'MatrixSDK', :git => 'https://github.com/matrix-org/matrix-ios-sdk.git', :branch => 'develop'
pod 'MatrixKit', :git => 'https://github.com/matrix-org/matrix-ios-kit.git', :branch => 'develop'

# The one used for developping both MatrixSDK and MatrixKit
# Note that MatrixSDK must be cloned into a folder called matrix-ios-sdk next to the MatrixKit folder
#pod 'MatrixKit', :path => '../matrix-ios-kit/MatrixKit.podspec'
#pod 'MatrixSDK', :path => '../matrix-ios-sdk/MatrixSDK.podspec'

pod 'GBDeviceInfo', '~> 3.4.0'

### OpenWebRTC call stack ###
# The wrapper lib between MatrixSDK and OpenWebRTC-SDK
#pod 'OpenWebRTC', '0.3.95'
pod 'MatrixOpenWebRTCWrapper', :git => 'https://github.com/matrix-org/matrix-ios-openwebrtc-wrapper.git', :branch => 'owr_update'
#pod 'MatrixOpenWebRTCWrapper', :path => '../matrix-ios-openwebrtc-wrapper/MatrixOpenWebRTCWrapper.podspec'
pod 'OpenWebRTC-SDK',  :git => 'https://github.com/EricssonResearch/openwebrtc-ios-sdk.git'

end
