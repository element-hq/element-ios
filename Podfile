# Uncomment this line to define a global platform for your project
platform :ios, '11.0'

# Use frameforks to allow usage of pod written in Swift (like PiwikTracker)
use_frameworks!

# Different flavours of pods to MatrixKit. Can be one of:
# - a String indicating an official MatrixKit released version number
# - `:local` (to use Development Pods)
# - `{'kit branch name' => 'sdk branch name'}` to depend on specific branches of each repo
# - `{ {kit spec hash} => {sdk spec hash}` to depend on specific pod options (:git => …, :podspec => …) for each repo. Used by Fastfile during CI
#
# Warning: our internal tooling depends on the name of this variable name, so be sure not to change it
$matrixKitVersion = '0.14.9'
# $matrixKitVersion = :local
# $matrixKitVersion = {'develop' => 'develop'}

########################################

case $matrixKitVersion
when :local
$matrixKitVersionSpec = { :path => '../matrix-ios-kit/MatrixKit.podspec' }
$matrixSDKVersionSpec = { :path => '../matrix-ios-sdk/MatrixSDK.podspec' }
when Hash # kit branch name => sdk branch name – or {kit spec Hash} => {sdk spec Hash}
kit_spec, sdk_spec = $matrixKitVersion.first # extract first and only key/value pair; key is kit_spec, value is sdk_spec
kit_spec = { :git => 'https://github.com/matrix-org/matrix-ios-kit.git', :branch => kit_spec.to_s } unless kit_spec.is_a?(Hash)
sdk_spec = { :git => 'https://github.com/matrix-org/matrix-ios-sdk.git', :branch => sdk_spec.to_s } unless sdk_spec.is_a?(Hash)
$matrixKitVersionSpec = kit_spec
$matrixSDKVersionSpec = sdk_spec
when String # specific MatrixKit released version
$matrixKitVersionSpec = $matrixKitVersion
$matrixSDKVersionSpec = {}
end

# Method to import the MatrixKit
def import_MatrixKit
  pod 'MatrixSDK', $matrixSDKVersionSpec
  pod 'MatrixSDK/JingleCallStack', $matrixSDKVersionSpec
  pod 'MatrixKit', $matrixKitVersionSpec
end

########################################

abstract_target 'RiotPods' do

  pod 'GBDeviceInfo', '~> 6.6.0'
  pod 'Reusable', '~> 4.1'
  pod 'KeychainAccess', '~> 4.2.2'
 
  # Piwik for analytics
  pod 'MatomoTracker', '~> 7.4.1'

  # Remove warnings from "bad" pods
  pod 'OLMKit', :inhibit_warnings => true
  pod 'zxcvbn-ios', :inhibit_warnings => true
  pod 'HPGrowingTextView', :inhibit_warnings => true

  # Tools
  pod 'SwiftGen', '~> 6.3'
  pod 'SwiftLint', '~> 0.43.0'

  target "Riot" do
    import_MatrixKit
    pod 'DGCollectionViewLeftAlignFlowLayout', '~> 1.0.4'
    pod 'KTCenterFlowLayout', '~> 1.3.1'
    pod 'ZXingObjC', '~> 3.6.5'
    pod 'FlowCommoniOS', '~> 1.10.0'
    pod 'ReadMoreTextView', '~> 3.0.1'
    pod 'SwiftBase32', '~> 0.9.0'
    pod 'SwiftJWT', '~> 3.6.200'

    target 'RiotTests' do
      inherit! :search_paths
    end
  end

  target "RiotShareExtension" do
    import_MatrixKit
  end

  target "SiriIntents" do
    import_MatrixKit
  end

  target "RiotNSE" do
    import_MatrixKit
  end

end


post_install do |installer|
  installer.pods_project.targets.each do |target|

    target.build_configurations.each do |config|
      # Disable bitcode for each pod framework
      # Because the WebRTC pod (included by the JingleCallStack pod) does not support it.
      # Plus the app does not enable it
      config.build_settings['ENABLE_BITCODE'] = 'NO'

      # Make fastlane(xcodebuild) happy by preventing it from building for arm64 simulator 
      config.build_settings["EXCLUDED_ARCHS[sdk=iphonesimulator*]"] = "arm64"

      # Force ReadMoreTextView to use Swift 5.2 version (as there is no code changes to perform)
      if target.name.include? 'ReadMoreTextView'
        config.build_settings['SWIFT_VERSION'] = '5.2'
      end

      # Stop Xcode 12 complaining about old IPHONEOS_DEPLOYMENT_TARGET from pods 
      config.build_settings.delete 'IPHONEOS_DEPLOYMENT_TARGET'
    end
  end
end
