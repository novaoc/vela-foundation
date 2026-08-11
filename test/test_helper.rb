ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

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
