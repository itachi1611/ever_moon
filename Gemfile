source "https://rubygems.org"

# Versions are locked by Gemfile.lock; the Ruby version is in .ruby-version.
gem "fastlane", "~> 2.241"

# Ruby 3.3 ships minitest as a bundled gem, and `bundle exec ruby` only sees
# gems that are in the lockfile, so the helper tests need it listed here.
gem "minitest", "~> 5.25"

plugins_path = File.join(File.dirname(__FILE__), "fastlane", "Pluginfile")
eval_gemfile(plugins_path) if File.exist?(plugins_path)
