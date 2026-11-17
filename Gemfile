source "https://rubygems.org"

# Versions are locked by Gemfile.lock; the Ruby version is in .ruby-version.
gem "fastlane", "~> 2.241"

plugins_path = File.join(File.dirname(__FILE__), "fastlane", "Pluginfile")
eval_gemfile(plugins_path) if File.exist?(plugins_path)
