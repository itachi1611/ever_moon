module Evermoon
  # Runs external commands from the project root and fails the lane when one
  # fails. Arguments are passed as an array, never through a shell string.
  module Shell
    def self.run(*command, chdir:)
      UI.info("$ #{command.join(' ')}")
      return if system(*command, chdir: chdir)

      UI.fail!("Command failed (exit #{$?.exitstatus}): #{command.join(' ')}")
    end

    # Whether an executable with this name is on the PATH.
    def self.on_path?(name)
      ENV.fetch("PATH", "").split(File::PATH_SEPARATOR).any? do |dir|
        File.executable?(File.join(dir, name))
      end
    end
  end
end
