source 'https://cdn.cocoapods.org/'

# Uncomment this line to define a global platform for your project
platform :ios, '12.1'

# Use frameforks to allow usage of pod written in Swift (like PiwikTracker)
use_frameworks!

# Different flavours of pods to MatrixSDK. Can be one of:
# - a String indicating an official MatrixSDK released version number
# - `:local` (to use Development Pods)
# - `{ :branch => 'sdk branch name'}` to depend on specific branch of MatrixSDK repo
# - `{ :specHash => {sdk spec hash}` to depend on specific pod options (:git => …, :podspec => …) for MatrixSDK repo. Used by Fastfile during CI
#
# Warning: our internal tooling depends on the name of this variable name, so be sure not to change it
$matrixSDKVersion = '= 0.20.13'
# $matrixSDKVersion = :local
# $matrixSDKVersion = { :branch => 'develop'}
# $matrixSDKVersion = { :specHash => { git: 'https://git.io/fork123', branch: 'fix' } }

########################################

case $matrixSDKVersion
when :local
$matrixSDKVersionSpec = { :path => '../matrix-ios-sdk/MatrixSDK.podspec' }
when Hash
spec_mode, sdk_spec = $matrixSDKVersion.first # extract first and only key/value pair; key is spec_mode, value is sdk_spec

  case spec_mode
  when :branch
  # :branch => sdk branch name
  sdk_spec = { :git => 'https://github.com/matrix-org/matrix-ios-sdk.git', :branch => sdk_spec.to_s } unless sdk_spec.is_a?(Hash)
  when :specHash
  # :specHash => {sdk spec Hash}
  sdk_spec = sdk_spec
  end

$matrixSDKVersionSpec = sdk_spec
when String # specific MatrixSDK released version
$matrixSDKVersionSpec = $matrixSDKVersion
end

# Method to import the MatrixSDK
def import_MatrixSDK
  pod 'MatrixSDK', $matrixSDKVersionSpec
  pod 'MatrixSDK/JingleCallStack', $matrixSDKVersionSpec
end

########################################

def import_MatrixKit_pods
  pod 'HPGrowingTextView', '~> 1.1'  
  pod 'libPhoneNumber-iOS', '~> 0.9.13'  
  pod 'DTCoreText', '~> 1.6.25'
  #pod 'DTCoreText/Extension', '~> 1.6.25'
  pod 'Down', '~> 0.11.0'
end

def import_SwiftUI_pods
    pod 'Introspect', '~> 0.1'
end

abstract_target 'RiotPods' do

  pod 'GBDeviceInfo', '~> 6.6.0'
  pod 'Reusable', '~> 4.1'
  pod 'KeychainAccess', '~> 4.2.2'
  pod 'WeakDictionary', '~> 2.0'

  # Piwik for analytics
  pod 'MatomoTracker', '~> 7.4.1'

  # Remove warnings from "bad" pods
  pod 'OLMKit', :inhibit_warnings => true
  pod 'zxcvbn-ios', :inhibit_warnings => true

  # Tools
  pod 'SwiftGen', '~> 6.3'
  pod 'SwiftLint', '~> 0.44.0'

  target "Riot" do
    import_MatrixSDK
    import_MatrixKit_pods

    import_SwiftUI_pods

    pod 'DGCollectionViewLeftAlignFlowLayout', '~> 1.0.4'
    pod 'KTCenterFlowLayout', '~> 1.3.1'
    pod 'ZXingObjC', '~> 3.6.5'
    pod 'FlowCommoniOS', '~> 1.12.0'
    pod 'ReadMoreTextView', '~> 3.0.1'
    pod 'SwiftBase32', '~> 0.9.0'
    pod 'SwiftJWT', '~> 3.6.200'
    pod 'SideMenu', '~> 6.5'
    pod 'DSWaveformImage', '~> 6.1.1'
    pod 'ffmpeg-kit-ios-audio', '~> 4.5'
    
    pod 'FLEX', '~> 4.5.0', :configurations => ['Debug']

    target 'RiotTests' do
      inherit! :search_paths
    end
  end

  target "RiotShareExtension" do
    import_MatrixSDK
    import_MatrixKit_pods
  end

  target "RiotSwiftUI" do
    import_SwiftUI_pods
  end 

  target "RiotSwiftUITests" do
    import_SwiftUI_pods
  end 

  target "SiriIntents" do
    import_MatrixSDK
    import_MatrixKit_pods
  end

  target "RiotNSE" do
    import_MatrixSDK
    import_MatrixKit_pods
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
