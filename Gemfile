source "https://rubygems.org"

gem "xcode-install"
gem "fastlane"
gem "cocoapods", '~>1.16.2'
gem "slather"
gem "tsort" # Won't be included in Ruby 4.1.0.

plugins_path = File.join(File.dirname(__FILE__), 'fastlane', 'Pluginfile')
eval_gemfile(plugins_path) if File.exist?(plugins_path)
