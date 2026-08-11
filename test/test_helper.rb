ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

# Drives OmniAuth in its test mode: the request phase never contacts a
# provider and instead redirects straight to the callback carrying the
# canned auth hash set by stub_oauth.
module OmniauthTestHelpers
  extend ActiveSupport::Concern

  included do
    teardown do
      OmniAuth.config.test_mode = false
      OmniAuth.config.mock_auth.except!(:google_oauth2, :github)
    end
  end

  def stub_oauth(provider, uid:, email:)
    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[provider] = OmniAuth::AuthHash.new(
      provider: provider.to_s,
      uid: uid,
      info: { email: email }
    )
  end
end

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    private

    # Runs the block with the given ENV entries applied (nil deletes a key),
    # restoring the previous values afterwards. Used by the offline-preview
    # and mail-selection matrices.
    def with_env(entries)
      previous = entries.keys.index_with { |key| ENV[key] }
      entries.each { |key, value| value.nil? ? ENV.delete(key) : ENV[key] = value }
      yield
    ensure
      previous.each { |key, value| value.nil? ? ENV.delete(key) : ENV[key] = value }
    end
  end
end
