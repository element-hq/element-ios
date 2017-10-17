# Uncomment this line to define a global platform for your project
platform :ios, "8.0"

source 'https://github.com/CocoaPods/Specs.git'


# Different flavours of pods to MatrixKit
# The current MatrixKit pod version
matrixKitPodVersion = '0.6.3'
matrixKitVersion = matrixKitPodVersion

# The develop branch version
#matrixKitVersion = 'develop'

# The one used for developing both MatrixSDK and MatrixKit
# Note that MatrixSDK must be cloned into a folder called matrix-ios-sdk next to the MatrixKit folder
#matrixKitVersion = 'local'


abstract_target 'RiotPods' do

    pod 'GBDeviceInfo', '~> 4.4.0'
    pod 'GoogleAnalytics'

    # The Google WebRTC stack
    pod 'WebRTC', '58.17.16937'

    # OLMKit for crypto
    pod 'OLMKit'
    #pod 'OLMKit', :path => '../olm/OLMKit.podspec'
    pod 'Realm', '~> 2.10.2'

    # Remove warnings from "bad" pods
    pod 'OLMKit', :inhibit_warnings => true
    pod 'cmark', :inhibit_warnings => true
    pod 'DTCoreText', :inhibit_warnings => true


    target "Riot" do

        if matrixKitVersion == matrixKitPodVersion
            pod 'MatrixKit', matrixKitVersion
        else
            if matrixKitVersion == 'local'
                pod 'MatrixSDK', :path => '../matrix-ios-sdk/MatrixSDK.podspec'
                pod 'MatrixKit', :path => '../matrix-ios-kit/MatrixKit.podspec'
            else
                pod 'MatrixSDK', :git => 'https://github.com/matrix-org/matrix-ios-sdk.git', :branch => 'develop'
                pod 'MatrixKit', :git => 'https://github.com/matrix-org/matrix-ios-kit.git', :branch => 'develop'
            end
        end 
    
    end

    
    target "RiotShareExtension" do

        if matrixKitVersion == matrixKitPodVersion
            pod 'MatrixKit/AppExtension', matrixKitVersion
        else
            if matrixKitVersion == 'local'
                pod 'MatrixSDK', :path => '../matrix-ios-sdk/MatrixSDK.podspec'
                pod 'MatrixKit/AppExtension', :path => '../matrix-ios-kit/MatrixKit.podspec'
            else
                pod 'MatrixSDK', :git => 'https://github.com/matrix-org/matrix-ios-sdk.git', :branch => 'develop'
                pod 'MatrixKit/AppExtension', :git => 'https://github.com/matrix-org/matrix-ios-kit.git', :branch => 'develop'
            end
        end 

    end


    target "SiriIntents" do

        if matrixKitVersion == matrixKitPodVersion
            pod 'MatrixKit/AppExtension', matrixKitVersion
        else
            if matrixKitVersion == 'local'
                pod 'MatrixSDK', :path => '../matrix-ios-sdk/MatrixSDK.podspec'
                pod 'MatrixKit/AppExtension', :path => '../matrix-ios-kit/MatrixKit.podspec'
            else
                pod 'MatrixSDK', :git => 'https://github.com/matrix-org/matrix-ios-sdk.git', :branch => 'develop'
                pod 'MatrixKit/AppExtension', :git => 'https://github.com/matrix-org/matrix-ios-kit.git', :branch => 'develop'
            end
        end 
    end
    
end

