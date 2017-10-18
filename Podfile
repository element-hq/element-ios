# Uncomment this line to define a global platform for your project
platform :ios, "8.0"

source 'https://github.com/CocoaPods/Specs.git'


# Different flavours of pods to MatrixKit
# The current MatrixKit pod version
$matrixKitVersion = '0.6.3'

# The develop branch version
#$matrixKitVersion = 'develop'

# The one used for developing both MatrixSDK and MatrixKit
# Note that MatrixSDK must be cloned into a folder called matrix-ios-sdk next to the MatrixKit folder
#$matrixKitVersion = 'local'


# Method to import the right MatrixKit flavour
def import_MatrixKit
    if $matrixKitVersion == 'local'
        pod 'MatrixSDK', :path => '../matrix-ios-sdk/MatrixSDK.podspec'
        pod 'MatrixKit', :path => '../matrix-ios-kit/MatrixKit.podspec'
    else
        if $matrixKitVersion == 'develop'
            pod 'MatrixSDK', :git => 'https://github.com/matrix-org/matrix-ios-sdk.git', :branch => 'develop'
            pod 'MatrixKit', :git => 'https://github.com/matrix-org/matrix-ios-kit.git', :branch => 'develop'
        else
            pod 'MatrixKit', $matrixKitVersion
        end
    end 
end

# Method to import the right MatrixKit/AppExtension flavour
def import_MatrixKitAppExtension
    if $matrixKitVersion == 'local'
        pod 'MatrixSDK', :path => '../matrix-ios-sdk/MatrixSDK.podspec'
        pod 'MatrixKit/AppExtension', :path => '../matrix-ios-kit/MatrixKit.podspec'
    else
        if $matrixKitVersion == 'develop'
            pod 'MatrixSDK', :git => 'https://github.com/matrix-org/matrix-ios-sdk.git', :branch => 'develop'
            pod 'MatrixKit/AppExtension', :git => 'https://github.com/matrix-org/matrix-ios-kit.git', :branch => 'develop'
        else
            pod 'MatrixKit/AppExtension', $matrixKitVersion
        end
    end 
end


abstract_target 'RiotPods' do

    pod 'GBDeviceInfo', '~> 4.4.0'
    pod 'GoogleAnalytics'

    # The Google WebRTC stack
    pod 'WebRTC', '61.5.19063'

    # OLMKit for crypto
    pod 'OLMKit'
    #pod 'OLMKit', :path => '../olm/OLMKit.podspec'
    pod 'Realm', '~> 2.10.2'

    # Remove warnings from "bad" pods
    pod 'OLMKit', :inhibit_warnings => true
    pod 'cmark', :inhibit_warnings => true
    pod 'DTCoreText', :inhibit_warnings => true


    target "Riot" do
        import_MatrixKit
    end
    
    target "RiotShareExtension" do
        import_MatrixKitAppExtension
    end

    target "SiriIntents" do
        import_MatrixKitAppExtension
    end
    
end

