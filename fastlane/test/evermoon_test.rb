require "minitest/autorun"
require "tmpdir"
require "fileutils"
require_relative "../lib/evermoon"

# Run from the repository root: bundle exec ruby fastlane/test/evermoon_test.rb
# Expected values come from the Firebase console and the Xcode project, not
# from the helpers under test.
class ProjectTest < Minitest::Test
  def test_flavors_come_from_firebase_json
    assert_equal %w[dev prod], Evermoon::Project.flavors
  end

  def test_unknown_flavor_is_rejected
    error = assert_raises(Evermoon::Error) { Evermoon::Project.flavor!("uat") }
    assert_includes error.message, "dev, prod"
  end

  def test_firebase_app_ids_for_every_flavor_and_platform
    {
      %w[dev android] => "1:738285598906:android:cbaaca2209de188a42aa83",
      %w[dev ios] => "1:738285598906:ios:c118cdd51775674642aa83",
      %w[prod android] => "1:279662008621:android:8e2f324f5ee09ecae8dba4",
      %w[prod ios] => "1:279662008621:ios:0c7117a3425201ace8dba4"
    }.each do |(flavor, platform), expected|
      assert_equal expected, Evermoon::Project.firebase_app_id(flavor, platform)
    end
  end

  def test_firebase_projects
    assert_equal "evermoon-dev", Evermoon::Project.firebase_project("dev")
    assert_equal "evermoon-2cc28", Evermoon::Project.firebase_project("prod")
  end

  def test_ios_bundle_ids
    assert_equal "com.fox.evermoon.dev", Evermoon::Project.ios_bundle_id("dev")
    assert_equal "com.fox.evermoon", Evermoon::Project.ios_bundle_id("prod")
  end

  def test_entry_point_follows_the_flavor
    assert_equal "lib/main_prod.dart", Evermoon::Project.entry_point("prod")
  end

  def test_tester_groups_default_and_override
    with_env("FIREBASE_TESTER_GROUPS" => nil) do
      assert_equal "testers", Evermoon::Project.tester_groups("dev")
    end
    with_env("FIREBASE_TESTER_GROUPS" => "family") do
      assert_equal "family", Evermoon::Project.tester_groups("prod")
    end
  end

  private

  def with_env(values)
    saved = values.keys.to_h { |key| [key, ENV[key]] }
    values.each { |key, value| ENV[key] = value }
    yield
  ensure
    saved.each { |key, value| ENV[key] = value }
  end
end

class FlutterTest < Minitest::Test
  def test_version_flags_skip_empty_values
    assert_equal ["--build-name=1.2.3", "--build-number=61"],
                 Evermoon::Flutter.version_flags("1.2.3", 61)
    assert_empty Evermoon::Flutter.version_flags(nil, "")
  end

  def test_fvm_is_used_only_when_installed
    Dir.mktmpdir do |bin|
      path = ENV["PATH"]
      ENV["PATH"] = bin
      assert_equal %w[flutter], Evermoon::Flutter.command
      File.write(File.join(bin, "fvm"), "#!/bin/sh\n")
      FileUtils.chmod(0o755, File.join(bin, "fvm"))
      assert_equal %w[fvm flutter], Evermoon::Flutter.command
    ensure
      ENV["PATH"] = path
    end
  end
end

class IosTest < Minitest::Test
  KEY = %w[ASC_KEY_PATH ASC_KEY_ID ASC_ISSUER_ID APPLE_TEAM_ID].freeze

  def setup
    @saved = KEY.to_h { |name| [name, ENV.delete(name)] }
  end

  def teardown
    @saved.each { |name, value| ENV[name] = value }
  end

  def test_signing_without_a_key_uses_the_logged_in_account
    assert_equal "-allowProvisioningUpdates", Evermoon::Ios.signing_xcargs
  end

  def test_signing_with_a_full_key
    ENV["ASC_KEY_PATH"] = "/tmp/k.p8"
    ENV["ASC_KEY_ID"] = "ABC"
    ENV["ASC_ISSUER_ID"] = "ISS"
    assert_equal "-allowProvisioningUpdates -authenticationKeyPath /tmp/k.p8 " \
                 "-authenticationKeyID ABC -authenticationKeyIssuerID ISS",
                 Evermoon::Ios.signing_xcargs
  end

  def test_a_partial_key_is_rejected
    ENV["ASC_KEY_ID"] = "ABC"
    error = assert_raises(Evermoon::Error) { Evermoon::Ios.signing_xcargs }
    assert_includes error.message, "ASC_KEY_PATH"
  end

  def test_archive_options_follow_the_flavor
    options = Evermoon::Ios.archive_options("prod")
    assert_equal "prod", options[:scheme]
    assert_equal "Release-prod", options[:configuration]
    assert_equal "ad-hoc", options[:export_method]
    refute options.key?(:export_team_id)
  end

  def test_team_id_is_passed_only_when_set
    ENV["APPLE_TEAM_ID"] = "TEAM123"
    assert_equal "TEAM123", Evermoon::Ios.archive_options("dev")[:export_team_id]
  end
end

class DistributionTest < Minitest::Test
  def test_missing_credentials_stop_before_any_build
    saved = ENV.delete("FIREBASE_SERVICE_CREDENTIALS")
    assert_raises(Evermoon::Error) do
      Evermoon::Distribution.firebase_params("dev", :android, nil)
    end
  ensure
    ENV["FIREBASE_SERVICE_CREDENTIALS"] = saved
  end

  def test_android_params
    Dir.mktmpdir do |dir|
      credentials = File.join(dir, "sa.json")
      File.write(credentials, "{}")
      ENV["FIREBASE_SERVICE_CREDENTIALS"] = credentials
      params = Evermoon::Distribution.firebase_params("prod", :android, "")
      assert_equal "1:279662008621:android:8e2f324f5ee09ecae8dba4", params[:app]
      assert_equal "prod build", params[:release_notes]
      assert_equal "APK", params[:android_artifact_type]
      assert params[:android_artifact_path].end_with?("app-prod-release.apk")
    ensure
      ENV.delete("FIREBASE_SERVICE_CREDENTIALS")
    end
  end
end
