# Uncomment this line to define a global platform for your project
platform :ios, '10.0'

# Use frameforks to allow usage of pod written in Swift (like PiwikTracker)
use_frameworks!

# $matrixKitPodSelectionBehaviors hash is used to determine which Matrix pods to use
#
# local: The one used for developing both MatrixSDK and MatrixKit. Note that MatrixSDK must be cloned into a folder called matrix-ios-sdk next to the MatrixKit folder.
# develop: Use MatrixKit develop branch.
# specifiedRelease: Use the MatrixKit pod version specified by $matrixKitVersion variable.
# currentGitBranch: Automatically determine MatrixKit pod to use based on current Riot iOS branch.
$matrixKitPodSelectionBehaviors = Hash[
    :local => "local",
    :develop => "develop",
    :specifiedRelease => "specified release",
    :currentGitBranch => "current Git branch"
]

# Git branch matching between Riot iOS and MatrixSDK
$matrixSDKBranchesMap = {
    "develop" => "develop",
    "xcode11" => "xcode11"
}

# Git branch matching between Riot iOS and MatrixKit
$matrixKitBranchesMap = {
    "develop" => "develop",
    "xcode11" => "xcode11"
}

# Podspec path locations used when choosing :local behavior
$localMatrixSDKPodspecPath = '../matrix-ios-sdk/MatrixSDK.podspec'
$localMatrixKitPodspecPath = '../matrix-ios-kit/MatrixKit.podspec'

# The current MatrixKit pod version used when choosing :specifiedRelease behavior
$matrixKitVersion = '0.11.4'

# Current MatrixKit pod selection behavior
$matrixKitPodSelectionBehavior = :currentGitBranch

# Used when choosing :currentGitBranch or :develop behavior
$selectedMatrixSDKBranch
$selectedMatrixKitBranch

# This hook allows to make any changes to the Pods after they have been downloaded but before they are installed.
pre_install do |installer|
    
    puts "Current MatrixKit pod selection behavior: " + $matrixKitPodSelectionBehaviors[$matrixKitPodSelectionBehavior]

    # Resolve Matrix pod branches to select if needed.
    case $matrixKitPodSelectionBehavior
        when :local
        puts "Select local Matrix pods"
        when :develop
        select_Matrix_pods_branches_from_branch_name('develop')
        puts "Select MatrixKit develop branch"
        when :specifiedRelease
        puts "Select MatrixKit specified version: " + $matrixKitVersion
        when :currentGitBranch
        select_matrix_pod_branches_from_current_branch
    end
    
end

# Select Matrix pods branches from current branch name
def select_Matrix_pods_branches_from_branch_name(branch_name)
    if branch_name.nil?
        return
    end
    
    $selectedMatrixSDKBranch = $matrixSDKBranchesMap[branch_name]
    $selectedMatrixKitBranch = $matrixKitBranchesMap[branch_name]
end

# Select Matrix pods branches from current Git branch
def select_matrix_pod_branches_from_current_branch
    
    currentBranchName = %x[git symbolic-ref --short -q HEAD]&.strip
    parentBranchName = %x[git log --pretty=format:'%D' HEAD^ | grep 'origin/' | head -n1 | sed 's@origin/@@' | sed 's@,.*@@']&.strip

    puts "Try to find Matrix pods branches from current Git branch. Current branch: '#{currentBranchName}', parent branch: '#{parentBranchName}'."
    
    if !currentBranchName.nil? || !parentBranchName.nil?
        select_Matrix_pods_branches_from_branch_name(currentBranchName)
        # Did not find matching branches from current branch try with parent branch
        if $selectedMatrixSDKBranch.nil? || $selectedMatrixKitBranch.nil?
            select_Matrix_pods_branches_from_branch_name(parentBranchName)
        end
    end
    
    # Fail to find matching branches fall back to :specifiedRelease behavior
    if $selectedMatrixSDKBranch.nil? || $selectedMatrixKitBranch.nil?
        puts "Fail to find suitable Matrix pods branches. Fallback to MatrixKit specified version: " + $matrixKitVersion
        $matrixKitPodSelectionBehavior = :specifiedRelease
    else
        puts "Select Matrix pods from current branch. MatrixKit: '#{$selectedMatrixSDKBranch}' & MatrixSDK: '#{$selectedMatrixKitBranch}'"
    end
end

# Import Matrix pods common to all targets
def import_Matrix_pods_common
    case $matrixKitPodSelectionBehavior
        when :local
        # pod 'OLMKit', :path => '../olm/OLMKit.podspec'
        pod 'MatrixSDK', :path => $localMatrixSDKPodspecPath
        pod 'MatrixSDK/SwiftSupport', :path => $localMatrixSDKPodspecPath
        pod 'MatrixSDK/JingleCallStack', :path => $localMatrixSDKPodspecPath
        when :develop, :currentGitBranch
        # pod 'OLMKit', :git => 'https://git.matrix.org/git/olm', :branch => 'master'
        pod 'MatrixSDK', :git => 'https://github.com/matrix-org/matrix-ios-sdk.git', :branch => $selectedMatrixSDKBranch
        pod 'MatrixSDK/SwiftSupport', :git => 'https://github.com/matrix-org/matrix-ios-sdk.git', :branch => $selectedMatrixSDKBranch
        pod 'MatrixSDK/JingleCallStack', :git => 'https://github.com/matrix-org/matrix-ios-sdk.git', :branch => $selectedMatrixSDKBranch
        else
        # pod 'OLMKit'
        pod 'MatrixSDK'
        pod 'MatrixSDK/SwiftSupport'
        pod 'MatrixSDK/JingleCallStack'
    end
end

# Import Matrix pods for the main target
def import_Matrix_pods_main_target
    import_Matrix_pods_common
    
    case $matrixKitPodSelectionBehavior
        when :local
        pod 'MatrixKit', :path => $localMatrixKitPodspecPath
        when :develop, :currentGitBranch
        pod 'MatrixKit', :git => 'https://github.com/matrix-org/matrix-ios-kit.git', :branch => $selectedMatrixKitBranch
        else
        pod 'MatrixKit', $matrixKitVersion
    end
end

# Import Matrix pods for an extension target
def import_Matrix_pods_extension_target
    import_Matrix_pods_common
    
    case $matrixKitPodSelectionBehavior
        when :local
        pod 'MatrixKit/AppExtension', :path => $localMatrixKitPodspecPath
        when :develop, :currentGitBranch
        pod 'MatrixKit/AppExtension', :git => 'https://github.com/matrix-org/matrix-ios-kit.git', :branch => $selectedMatrixKitBranch
        else
        pod 'MatrixKit/AppExtension', $matrixKitVersion
    end
end

# Abstract target used for convenient target dependency inheritance
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
        import_Matrix_pods_main_target
        pod 'DGCollectionViewLeftAlignFlowLayout', '~> 1.0.4'        
        pod 'ZXingObjC', '~> 3.6.5'
        
        target 'RiotTests' do
            inherit! :search_paths
        end
    end
    
    target "RiotShareExtension" do
        import_Matrix_pods_extension_target
    end

    target "SiriIntents" do
        import_Matrix_pods_extension_target
    end
    
end

# This hook allows to make any last changes to the generated Xcode project before it is written to disk, or any other tasks you might want to perform.
post_install do |installer|
    installer.pods_project.targets.each do |target|

        # Disable bitcode for each pod framework
        # Because the WebRTC pod (included by the JingleCallStack pod) does not support it.
        # Plus the app does not enable it
        target.build_configurations.each do |config|
            config.build_settings['ENABLE_BITCODE'] = 'NO'
        end
    end
end
