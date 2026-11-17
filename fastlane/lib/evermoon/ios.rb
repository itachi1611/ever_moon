module Evermoon
  # iOS release build. Flutter prepares the project (no code signing), then
  # fastlane's `build_app` archives and exports it with the options below.
  module Ios
    # The Xcode build configuration of a flavor (Release-dev, Release-prod).
    def self.configuration(flavor)
      "Release-#{flavor}"
    end

    def self.prepare(flavor, build_name, build_number)
      Flutter.prepare
      Flutter.run(
        "build", "ios", "--release", "--no-codesign", "--flavor", flavor,
        "-t", Project.entry_point(flavor),
        *Flutter.version_flags(build_name, build_number)
      )
    end

    def self.ipa_dir
      Project.path("build", "ios", "ipa")
    end

    def self.ipa_path(flavor)
      File.join(ipa_dir, "#{ipa_name(flavor)}.ipa")
    end

    def self.ipa_name(flavor)
      "ever_moon-#{flavor}"
    end

    # Parameters for `build_app`. Export method `ad-hoc` is what Firebase App
    # Distribution installs (the testers' devices must be registered).
    def self.archive_options(flavor)
      {
        workspace: Project.path("ios", "Runner.xcworkspace"),
        scheme: flavor,
        configuration: configuration(flavor),
        export_method: "ad-hoc",
        output_directory: ipa_dir,
        output_name: ipa_name(flavor),
        xcargs: signing_xcargs,
        export_team_id: ENV["APPLE_TEAM_ID"].to_s.empty? ? nil : ENV["APPLE_TEAM_ID"]
      }.compact
    end

    # Automatic signing. With an App Store Connect API key (CI) Xcode signs
    # without a logged-in Apple account; without one it uses the account that
    # is logged in to Xcode.
    def self.signing_xcargs
      args = %w[-allowProvisioningUpdates]
      key = api_key_env
      return args.join(" ") if key.values.all?(&:empty?)

      missing = key.select { |_, value| value.empty? }.keys
      UI.fail!("Set #{missing.join(', ')} too: the App Store Connect key needs all three.") unless missing.empty?

      args.push("-authenticationKeyPath", key["ASC_KEY_PATH"],
                "-authenticationKeyID", key["ASC_KEY_ID"],
                "-authenticationKeyIssuerID", key["ASC_ISSUER_ID"]).join(" ")
    end

    def self.api_key_env
      %w[ASC_KEY_PATH ASC_KEY_ID ASC_ISSUER_ID].to_h { |name| [name, ENV[name].to_s] }
    end

    private_class_method :api_key_env
  end
end
