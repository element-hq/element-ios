source "https://rubygems.org"

gem "xcode-install"
gem "fastlane"
gem "cocoapods", '~>1.14.3'
gem "slather"

plugins_path = File.join(File.dirname(__FILE__), 'fastlane', 'Pluginfile')
eval_gemfile(plugins_path) if File.exist?(plugins_path)
