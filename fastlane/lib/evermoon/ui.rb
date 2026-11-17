module Evermoon
  # Raised outside fastlane (unit tests); inside fastlane the same call stops
  # the lane with a plain message instead of a stack trace.
  Error = Class.new(StandardError)

  # Reporting that works with and without fastlane loaded.
  module UI
    def self.fail!(message)
      raise Error, message unless defined?(FastlaneCore::UI)

      FastlaneCore::UI.user_error!(message)
    end

    def self.info(message)
      if defined?(FastlaneCore::UI)
        FastlaneCore::UI.message(message)
      else
        puts(message)
      end
    end
  end
end
