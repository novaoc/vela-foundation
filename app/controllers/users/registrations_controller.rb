class Users::RegistrationsController < Devise::RegistrationsController
  # Cloudflare Turnstile guards account creation (SPEC M2.2). The helper is
  # a no-op wherever Turnstile is disabled (test) or unconfigured.
  before_action :validate_cloudflare_turnstile, only: :create

  before_action :configure_sign_up_params, only: :create

  # On top of Devise's create, persist the legal assent the user just gave
  # (SPEC M2.4): which document versions, when, from which IP/user agent,
  # and in which flow.
  def create
    super do |user|
      record_legal_acceptance(user) if user.persisted?
    end
  end

  private

  def configure_sign_up_params
    devise_parameter_sanitizer.permit(:sign_up, keys: [ :legal_assent ])
  end

  def record_legal_acceptance(user)
    user.legal_acceptances.create!(
      terms_version: Foundation::Legal::TERMS_VERSION,
      privacy_version: Foundation::Legal::PRIVACY_VERSION,
      accepted_at: Time.current,
      ip: request.remote_ip,
      user_agent: request.user_agent.to_s.byteslice(0, 255),
      context: "signup"
    )
  end
end
