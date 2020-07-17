# Uncomment this line to define a global platform for your project
platform :ios, '11.0'

# Use frameforks to allow usage of pod written in Swift (like PiwikTracker)
use_frameworks!


# Different flavours of pods to MatrixKit
# The current MatrixKit pod version
$matrixKitVersion = '0.12.8'

# The specific branch version (supported: develop)
#$matrixKitVersion = 'develop'

# The one used for developing both MatrixSDK and MatrixKit
# Note that MatrixSDK must be cloned into a folder called matrix-ios-sdk next to the MatrixKit folder
#$matrixKitVersion = 'local'


# Method to import the right MatrixKit flavour
def import_MatrixKit
    if $matrixKitVersion == 'local'
        pod 'MatrixSDK', :path => '../matrix-ios-sdk/MatrixSDK.podspec'
        pod 'MatrixSDK/SwiftSupport', :path => '../matrix-ios-sdk/MatrixSDK.podspec'
        pod 'MatrixSDK/JingleCallStack', :path => '../matrix-ios-sdk/MatrixSDK.podspec'
        pod 'MatrixKit', :path => '../matrix-ios-kit/MatrixKit.podspec'
    else
        if $matrixKitVersion == 'develop'
            pod 'MatrixSDK', :git => 'https://github.com/matrix-org/matrix-ios-sdk.git', :branch => $matrixKitVersion
            pod 'MatrixSDK/SwiftSupport', :git => 'https://github.com/matrix-org/matrix-ios-sdk.git', :branch => $matrixKitVersion
            pod 'MatrixSDK/JingleCallStack', :git => 'https://github.com/matrix-org/matrix-ios-sdk.git', :branch => $matrixKitVersion
            pod 'MatrixKit', :git => 'https://github.com/matrix-org/matrix-ios-kit.git', :branch => $matrixKitVersion
        else
            pod 'MatrixKit', $matrixKitVersion
            pod 'MatrixSDK/SwiftSupport'
            pod 'MatrixSDK/JingleCallStack'
        end
    end 
end

# Method to import the right MatrixKit/AppExtension flavour
def import_MatrixKitAppExtension
    if $matrixKitVersion == 'local'
        pod 'MatrixSDK', :path => '../matrix-ios-sdk/MatrixSDK.podspec'
        pod 'MatrixSDK/SwiftSupport', :path => '../matrix-ios-sdk/MatrixSDK.podspec'
        pod 'MatrixKit/AppExtension', :path => '../matrix-ios-kit/MatrixKit.podspec'
    else
        if $matrixKitVersion == 'develop'
            pod 'MatrixSDK', :git => 'https://github.com/matrix-org/matrix-ios-sdk.git', :branch => $matrixKitVersion
            pod 'MatrixSDK/SwiftSupport', :git => 'https://github.com/matrix-org/matrix-ios-sdk.git', :branch => $matrixKitVersion
            pod 'MatrixKit/AppExtension', :git => 'https://github.com/matrix-org/matrix-ios-kit.git', :branch => $matrixKitVersion
        else
            pod 'MatrixKit/AppExtension', $matrixKitVersion
            pod 'MatrixSDK/SwiftSupport'
        end
    end 
end


abstract_target 'RiotPods' do

    pod 'GBDeviceInfo', '~> 6.3.0'
    pod 'Reusable', '~> 4.1'
 
    # Piwik for analytics
    pod 'MatomoTracker', '~> 7.2.0'

    # Remove warnings from "bad" pods
    pod 'OLMKit', :inhibit_warnings => true
    pod 'cmark', :inhibit_warnings => true
    pod 'zxcvbn-ios'

    # Tools
    pod 'SwiftGen', '~> 6.1'
    pod 'SwiftLint', '~> 0.36.0'

    target "Riot" do
        import_MatrixKit
        pod 'DGCollectionViewLeftAlignFlowLayout', '~> 1.0.4'        
        pod 'KTCenterFlowLayout', '~> 1.3.1'
        pod 'ZXingObjC', '~> 3.6.5'
        
        target 'RiotTests' do
            inherit! :search_paths
        end
    end
    
    target "RiotShareExtension" do
        import_MatrixKitAppExtension
    end

    target "SiriIntents" do
        import_MatrixKitAppExtension
    end
    
    target "RiotNSE" do
        import_MatrixKitAppExtension
    end
    
end


post_install do |installer|
    installer.pods_project.targets.each do |target|

        # Disable bitcode for each pod framework
        # Because the WebRTC pod (included by the JingleCallStack pod) does not support it.
        # Plus the app does not enable it
        target.build_configurations.each do |config|
            config.build_settings['ENABLE_BITCODE'] = 'NO'
            
            # Force SwiftUTI Swift version to 5.0 (as there is no code changes to perform for SwiftUTI fork using Swift 4.2)
            if target.name.include? 'SwiftUTI'
                config.build_settings['SWIFT_VERSION'] = '5.0'
            end
        end
    end
end

