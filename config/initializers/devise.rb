# Devise configuration, overrides only — anything not listed here runs on
# Devise's own defaults (see the devise README for the full catalogue).

require "devise/orm/active_record"

Devise.setup do |config|
  # Auth mail (confirmation, reset, unlock) comes from the operator support
  # mailbox defined in config/foundation.yml.
  config.mailer_sender = Rails.configuration.x.foundation[:support_email]

  # Emails are matched case-insensitively and with surrounding whitespace
  # stripped, so "  Jane@Example.COM " signs in as jane@example.com.
  config.case_insensitive_keys = [ :email ]
  config.strip_whitespace_keys = [ :email ]

  # Session cookies only; no credential caching for HTTP auth.
  config.skip_session_storage = [ :http_auth ]

  # Full bcrypt cost in real environments; the minimum cost in tests, where
  # hashing speed dominates suite runtime and security is irrelevant.
  config.stretches = Rails.env.test? ? 1 : 12

  # SPEC M2.1: passwords are at least 12 characters.
  config.password_length = 12..128

  # Loose shape check only (one @, no spaces); the confirmation email is the
  # real proof of deliverability.
  config.email_regexp = /\A[^@\s]+@[^@\s]+\z/

  # Changing your email re-runs confirmation against the new address and
  # keeps the old one active until the link is clicked.
  config.reconfirmable = true

  # SPEC M2.1: lock the account after repeated failed sign-ins. Ten tries,
  # then unlock via emailed link or automatically after an hour.
  config.lock_strategy = :failed_attempts
  config.maximum_attempts = 10
  config.unlock_strategy = :both
  config.unlock_in = 1.hour

  # Password-reset links expire after six hours.
  config.reset_password_within = 6.hours

  # Signing out anywhere clears remember-me cookies on every device.
  config.expire_all_remember_me_on_sign_out = true

  # Sign-out is a DELETE (the layout uses button_to), never a crawlable GET.
  config.sign_out_via = :delete

  # Hotwire/Turbo-friendly statuses: 422 re-renders forms, 303 follows
  # redirects after non-GET requests.
  config.responder.error_status = :unprocessable_content
  config.responder.redirect_status = :see_other
end
