# One row per assent event: which versions of the terms and privacy policy a
# user accepted, when, from where, and in what flow (context, e.g. "signup").
# Rows are written at registration and kept for the life of the account as an
# audit trail; they are never updated in place.
class LegalAcceptance < ApplicationRecord
  belongs_to :user

  validates :terms_version, :privacy_version, :accepted_at, :context, presence: true
end
