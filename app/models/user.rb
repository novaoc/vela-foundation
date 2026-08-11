class User < ApplicationRecord
  # :timeoutable is deliberately not enabled: sessions are long-lived via
  # :rememberable, and an idle timeout on top of remember-me cookies mostly
  # produces surprise logouts. Enable it here if your product needs one.
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :confirmable, :lockable

  has_many :legal_acceptances, dependent: :destroy

  # Virtual attribute backing the signup assent checkbox. Registration posts
  # "1" when the box is ticked; anything else (including a missing param —
  # hence allow_nil: false) fails validation, so assent is enforced
  # server-side and not just by the form markup. Non-registration creation
  # paths (console, seeds, future OAuth interstitial) must set it explicitly,
  # which keeps "an account exists" equivalent to "assent was given".
  attr_accessor :legal_assent
  validates :legal_assent, acceptance: { allow_nil: false }, on: :create

  # Refuse throwaway mailboxes at registration (SPEC M2.3). Checked only on
  # create: a domain later added to the blocklist must not brick the account
  # that legitimately registered before it was listed.
  validates :email, nondisposable: true, on: :create

  before_create :skip_confirmation_for_offline_preview

  private

  # SPEC M2.5 / M9.3: a hosted preview without an SMTP relay cannot deliver
  # the confirmation email, so accounts are confirmed immediately there.
  # Everywhere else the normal Devise confirmable flow applies.
  def skip_confirmation_for_offline_preview
    skip_confirmation! if Foundation.offline_preview?
  end
end
