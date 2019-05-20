# Uncomment this line to define a global platform for your project
platform :ios, '10.0'

# Use frameforks to allow usage of pod written in Swift (like PiwikTracker)
use_frameworks!


# Different flavours of pods to MatrixKit
# The current MatrixKit pod version
$matrixKitVersion = '0.9.9'

# The develop branch version
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
            pod 'MatrixSDK', :git => 'https://github.com/matrix-org/matrix-ios-sdk.git', :branch => 'develop'
            pod 'MatrixSDK/SwiftSupport', :git => 'https://github.com/matrix-org/matrix-ios-sdk.git', :branch => 'develop'
            pod 'MatrixSDK/JingleCallStack', :git => 'https://github.com/matrix-org/matrix-ios-sdk.git', :branch => 'develop'
            pod 'MatrixKit', :git => 'https://github.com/matrix-org/matrix-ios-kit.git', :branch => 'develop'
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
            pod 'MatrixSDK', :git => 'https://github.com/matrix-org/matrix-ios-sdk.git', :branch => 'develop'
            pod 'MatrixSDK/SwiftSupport', :git => 'https://github.com/matrix-org/matrix-ios-sdk.git', :branch => 'develop'
            pod 'MatrixKit/AppExtension', :git => 'https://github.com/matrix-org/matrix-ios-kit.git', :branch => 'develop'
        else
            pod 'MatrixKit/AppExtension', $matrixKitVersion
            pod 'MatrixSDK/SwiftSupport'
        end
    end 
end


abstract_target 'RiotPods' do

    pod 'GBDeviceInfo', '~> 5.2.0'
    pod 'Reusable', '~> 4.0'

    # Piwik for analytics
    # While https://github.com/matomo-org/matomo-sdk-ios/pull/223 is not released, use the PR branch
    pod 'PiwikTracker', :git => 'https://github.com/manuroe/matomo-sdk-ios.git', :branch => 'feature/CustomVariables'
    #pod 'PiwikTracker', '~> 4.4.2'

    # Remove warnings from "bad" pods
    pod 'OLMKit', :inhibit_warnings => true
    pod 'cmark', :inhibit_warnings => true
    pod 'DTCoreText', :inhibit_warnings => true
    pod 'zxcvbn-ios'
    
    # Tools
    pod 'SwiftGen', '~> 6.1'
    pod 'SwiftLint', '~> 0.30.1'

    target "Riot" do
        import_MatrixKit
        pod 'DGCollectionViewLeftAlignFlowLayout', '~> 1.0.4'
    end
    
    target "RiotShareExtension" do
        import_MatrixKitAppExtension
    end

    target "SiriIntents" do
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
            
            # Required for PiwikTracker as `swift_version` is not defined in podspec. Should be removed
            if target.name.include? 'PiwikTracker'
                config.build_settings['SWIFT_VERSION'] = '4.0'
            end
        end

    end
end

