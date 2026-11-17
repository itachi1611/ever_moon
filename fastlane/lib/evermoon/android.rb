module Evermoon
  # Android release build.
  module Android
    # Builds the release APK of a flavor and returns its path. The signing key
    # is chosen by Gradle: debug key for dev, release keystore for prod
    # (android/app/build.gradle.kts).
    def self.build_apk(flavor, build_name, build_number)
      Flutter.prepare
      Flutter.run(
        "build", "apk", "--release", "--flavor", flavor,
        "-t", Project.entry_point(flavor),
        *Flutter.version_flags(build_name, build_number)
      )
      apk_path(flavor).tap do |path|
        UI.fail!("APK not found at #{path}") unless File.exist?(path)
      end
    end

    def self.apk_path(flavor)
      Project.path("build", "app", "outputs", "flutter-apk", "app-#{flavor}-release.apk")
    end
  end
end
