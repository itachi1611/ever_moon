module Evermoon
  # Android release builds: an APK (testers, Firebase) or an app bundle (Play).
  module Android
    # Builds the release APK of a flavor and returns its path. The signing key
    # is chosen by Gradle: debug key for dev, release keystore for prod
    # (android/app/build.gradle.kts).
    def self.build_apk(flavor, build_name, build_number)
      build("apk", flavor, build_name, build_number, apk_path(flavor))
    end

    # Builds the release app bundle (.aab) of a flavor and returns its path.
    def self.build_aab(flavor, build_name, build_number)
      build("appbundle", flavor, build_name, build_number, aab_path(flavor))
    end

    def self.apk_path(flavor)
      Project.path("build", "app", "outputs", "flutter-apk", "app-#{flavor}-release.apk")
    end

    def self.aab_path(flavor)
      Project.path("build", "app", "outputs", "bundle", "#{flavor}Release", "app-#{flavor}-release.aab")
    end

    def self.build(kind, flavor, build_name, build_number, path)
      Flutter.prepare
      Flutter.run(
        "build", kind, "--release", "--flavor", flavor,
        "-t", Project.entry_point(flavor),
        *Flutter.version_flags(build_name, build_number)
      )
      path.tap { |p| UI.fail!("Build output not found at #{p}") unless File.exist?(p) }
    end

    private_class_method :build
  end
end
