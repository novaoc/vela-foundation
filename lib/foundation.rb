# Namespace for original foundation code (SPEC global conventions).
module Foundation
  # True when the app is running as a hosted Holodex preview that has no
  # SMTP relay configured (SPEC M2.5 / M9.3). The preview flag is injected
  # by the Holodex runtime; a generated app never sets it itself.
  #
  # In this state outbound mail is impossible (previews have no egress), so
  # flows that would otherwise depend on delivering an email — most notably
  # Devise's confirmation step — must degrade gracefully. Later milestones
  # (M8 checkout simulator, M9 mail selection) reuse this same predicate so
  # the definition lives in exactly one place.
  def self.offline_preview?
    ENV["VELA_HOLODEX_PREVIEW"] == "1" && ENV["SMTP_ADDRESS"].blank?
  end
end
