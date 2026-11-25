module Evermoon
  # Parameters for the `upload_to_play_store` action. Only the prod flavor is on
  # Google Play: the dev flavor has another application id that does not exist
  # there. Only the app bundle is uploaded; the store listing (texts, images,
  # release notes) is edited in the Play Console.
  module Play
    FLAVOR = "prod".freeze
    # internal: invited testers, alpha: closed testing, beta: open testing.
    TRACKS = %w[internal alpha beta production].freeze
    # A staged rollout (`inProgress`) is chosen by passing a rollout fraction.
    STATUSES = %w[completed draft].freeze

    # `track` is required: a store upload is never made to a default track.
    def self.upload_params(track:, rollout: nil, release_status: nil, validate_only: false)
      track = track!(track)
      key = credentials
      fraction = rollout_fraction!(track, rollout)
      status = status!(release_status, fraction)
      base = {
        package_name: Project.android_application_id,
        json_key: key,
        track: track,
        aab: Android.aab_path(FLAVOR),
        release_status: status,
        validate_only: truthy?(validate_only)
      }
      base.merge(skip_params).merge(fraction ? { rollout: fraction.to_s } : {})
    end

    def self.track!(name)
      track = name.to_s
      return track if TRACKS.include?(track)

      UI.fail!("Unknown or missing track '#{track}'. Use one of: #{TRACKS.join(', ')}.")
    end

    # The service account JSON of the Google Play Console API access.
    def self.credentials
      path = ENV["PLAY_SERVICE_CREDENTIALS"].to_s
      return path if !path.empty? && File.exist?(path)

      UI.fail!("PLAY_SERVICE_CREDENTIALS must point to the Google Play service account JSON file.")
    end

    # nil for a full release, otherwise a Float in (0, 1). 1 means everybody.
    def self.rollout_fraction!(track, rollout)
      return nil if rollout.to_s.empty?

      UI.fail!("A staged rollout is only for the production track.") unless track == "production"
      fraction = Float(rollout.to_s, exception: false)
      UI.fail!("Rollout must be a number above 0 and up to 1, for example 0.1.") unless fraction&.positive? && fraction <= 1
      fraction == 1 ? nil : fraction
    end

    def self.status!(release_status, fraction)
      requested = release_status.to_s
      UI.fail!("A staged rollout cannot be a draft.") if fraction && requested == "draft"
      return "inProgress" if fraction
      return "completed" if requested.empty?
      return requested if STATUSES.include?(requested)

      UI.fail!("Unknown release status '#{requested}'. Use one of: #{STATUSES.join(', ')}.")
    end

    def self.skip_params
      {
        skip_upload_apk: true,
        skip_upload_metadata: true,
        skip_upload_changelogs: true,
        skip_upload_images: true,
        skip_upload_screenshots: true
      }
    end

    def self.truthy?(value)
      %w[true 1 yes].include?(value.to_s.downcase)
    end

    private_class_method :credentials, :rollout_fraction!, :status!, :skip_params, :truthy?
  end
end
