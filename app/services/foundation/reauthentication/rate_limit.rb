# frozen_string_literal: true

require "ipaddr"

module Foundation
  module Reauthentication
    class RateLimit
      WINDOW = 15.minutes
      LIMITS = { "account" => 5, "ip" => 20 }.freeze
      class Exceeded < StandardError; end

      def self.check!(account_id:, ip:)
        normalized_ip = IPAddr.new(ip.to_s).to_s
        keys = {
          "account" => Digest::SHA256.hexdigest("account:#{account_id}"),
          "ip" => Digest::SHA256.hexdigest("ip:#{normalized_ip}")
        }
        Foundation::ReauthenticationAttempt.transaction do
          keys.values.sort.each { |digest| advisory_lock!(digest) }
          keys.each do |kind, digest|
            count = Foundation::ReauthenticationAttempt
              .where(kind: kind, key_digest: digest, created_at: WINDOW.ago..)
              .count
            raise Exceeded if count >= LIMITS.fetch(kind)
          end
          keys.each do |kind, digest|
            Foundation::ReauthenticationAttempt.create!(
              kind: kind,
              key_digest: digest,
              created_at: Time.current
            )
          end
        end
        true
      rescue IPAddr::InvalidAddressError
        raise Exceeded
      end

      def self.purge!
        Foundation::ReauthenticationAttempt.where(created_at: ...1.day.ago).delete_all
      end

      def self.advisory_lock!(digest)
        unsigned = digest.first(16).to_i(16)
        signed = unsigned >= (1 << 63) ? unsigned - (1 << 64) : unsigned
        Foundation::ReauthenticationAttempt.connection.execute(
          "SELECT pg_advisory_xact_lock(#{signed})"
        )
      end
      private_class_method :advisory_lock!
    end
  end
end
