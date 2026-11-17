module Evermoon
  # Flutter and Dart commands. On a machine with fvm the pinned SDK is used;
  # the CI runner has no fvm and uses the Flutter that the setup action put on
  # the PATH.
  module Flutter
    def self.command
      fvm? ? %w[fvm flutter] : %w[flutter]
    end

    def self.dart_command
      fvm? ? %w[fvm dart] : %w[dart]
    end

    def self.fvm?
      Shell.on_path?("fvm") && File.exist?(Project.path(".fvmrc"))
    end

    def self.run(*args)
      Shell.run(*command, *args, chdir: Project.root)
    end

    # Generated code (build_runner, gen-l10n) is gitignored, so a fresh
    # checkout needs these steps before any build.
    def self.prepare
      run("pub", "get")
      Shell.run(*dart_command, "run", "build_runner", "build", chdir: Project.root)
    end

    # The version testers see; empty parts are left out.
    def self.version_flags(build_name, build_number)
      flags = []
      flags << "--build-name=#{build_name}" unless build_name.to_s.empty?
      flags << "--build-number=#{build_number}" unless build_number.to_s.empty?
      flags
    end
  end
end
