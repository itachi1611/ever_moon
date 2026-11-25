require "json"
require "yaml"

module Evermoon
  # Reads the project's own files instead of repeating their values here:
  # `firebase.json` (flavors and Firebase app ids, written by flutterfire),
  # `ios/Flutter/<flavor>-Release.xcconfig` (iOS bundle id) and
  # `fastlane/distribution.yml` (tester groups).
  module Project
    # The repository root (fastlane/lib/evermoon -> root).
    ROOT = File.expand_path("../../..", __dir__)

    FIREBASE_OPTIONS_KEY = %r{\Alib/firebase/([^/]+)/firebase_options\.dart\z}

    def self.root
      ROOT
    end

    def self.path(*parts)
      File.join(ROOT, *parts)
    end

    # Flavor names in the order of `firebase.json`.
    def self.flavors
      firebase_dart_options.keys.filter_map { |key| key[FIREBASE_OPTIONS_KEY, 1] }
    end

    # Returns the flavor name, or stops the lane when it is not a flavor.
    def self.flavor!(name)
      flavor = name.to_s
      return flavor if flavors.include?(flavor)

      UI.fail!("Unknown flavor '#{flavor}'. Known flavors: #{flavors.join(', ')}.")
    end

    def self.entry_point(flavor)
      "lib/main_#{flavor}.dart"
    end

    # `platform` is "android" or "ios".
    def self.firebase_app_id(flavor, platform)
      app_id = firebase_options(flavor).dig("configurations", platform.to_s)
      return app_id if app_id

      UI.fail!("firebase.json has no #{platform} app for flavor '#{flavor}'.")
    end

    # The Android application id (package name) of the prod flavor: the one in
    # `defaultConfig`, which only the dev flavor extends with a suffix.
    def self.android_application_id
      file = path("android", "app", "build.gradle.kts")
      UI.fail!("Missing #{file}") unless File.exist?(file)
      File.read(file)[/^\s*applicationId\s*=\s*"([^"]+)"/, 1] ||
        UI.fail!("#{file} does not set applicationId.")
    end

    def self.firebase_project(flavor)
      firebase_options(flavor).fetch("projectId")
    end

    # Comma separated group aliases; FIREBASE_TESTER_GROUPS overrides the file.
    def self.tester_groups(flavor)
      override = ENV["FIREBASE_TESTER_GROUPS"].to_s
      return override unless override.empty?

      groups = distribution.dig(flavor, "groups")
      return groups if groups

      UI.fail!("fastlane/distribution.yml has no groups for flavor '#{flavor}'.")
    end

    def self.ios_bundle_id(flavor)
      file = path("ios", "Flutter", "#{flavor}-Release.xcconfig")
      UI.fail!("Missing #{file}") unless File.exist?(file)
      File.read(file)[/^PRODUCT_BUNDLE_IDENTIFIER\s*=\s*(\S+)/, 1] ||
        UI.fail!("#{file} does not set PRODUCT_BUNDLE_IDENTIFIER.")
    end

    def self.firebase_dart_options
      data = JSON.parse(File.read(path("firebase.json")))
      data.dig("flutter", "platforms", "dart") ||
        UI.fail!("firebase.json has no flutter.platforms.dart section.")
    end

    def self.firebase_options(flavor)
      firebase_dart_options.fetch("lib/firebase/#{flavor}/firebase_options.dart") do
        UI.fail!("firebase.json has no entry for flavor '#{flavor}'.")
      end
    end

    def self.distribution
      YAML.safe_load(File.read(path("fastlane", "distribution.yml"))) || {}
    end

    private_class_method :firebase_dart_options, :firebase_options, :distribution
  end
end
