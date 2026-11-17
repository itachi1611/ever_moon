module Evermoon
  # Parameters for the `firebase_app_distribution` action.
  module Distribution
    # `platform` is :android or :ios; `flavor` must be a known flavor.
    def self.firebase_params(flavor, platform, notes)
      {
        app: Project.firebase_app_id(flavor, platform),
        groups: Project.tester_groups(flavor),
        release_notes: notes.to_s.empty? ? "#{flavor} build" : notes.to_s,
        service_credentials_file: credentials
      }.merge(artifact_params(flavor, platform))
    end

    def self.artifact_params(flavor, platform)
      case platform.to_sym
      when :android
        { android_artifact_type: "APK", android_artifact_path: Android.apk_path(flavor) }
      when :ios
        { ipa_path: Ios.ipa_path(flavor) }
      else
        UI.fail!("Unknown platform '#{platform}'.")
      end
    end

    # The service account JSON of the flavor's Firebase project.
    def self.credentials
      path = ENV["FIREBASE_SERVICE_CREDENTIALS"].to_s
      return path if !path.empty? && File.exist?(path)

      UI.fail!("FIREBASE_SERVICE_CREDENTIALS must point to the service account JSON file.")
    end

    private_class_method :artifact_params, :credentials
  end
end
