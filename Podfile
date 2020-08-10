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
$matrixKitVersion = '0.12.11'
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

# Method to import the right MatrixKit flavour
def import_MatrixKit
  pod 'MatrixSDK', $matrixSDKVersionSpec
  pod 'MatrixSDK/SwiftSupport', $matrixSDKVersionSpec
  pod 'MatrixSDK/JingleCallStack', $matrixSDKVersionSpec
  pod 'MatrixKit', $matrixKitVersionSpec
end

# Method to import the right MatrixKit/AppExtension flavour
def import_MatrixKitAppExtension
  pod 'MatrixSDK', $matrixSDKVersionSpec
  pod 'MatrixSDK/SwiftSupport', $matrixSDKVersionSpec
  pod 'MatrixKit/AppExtension', $matrixKitVersionSpec
end

########################################

abstract_target 'RiotPods' do

  pod 'GBDeviceInfo', '~> 6.3.0'
  pod 'Reusable', '~> 4.1'
  pod 'KeychainAccess', '~> 4.2'
 
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
