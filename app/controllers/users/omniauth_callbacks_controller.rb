# Receives the OmniAuth callback phase for every provider and enforces the
# account-linking contract (SPEC M3.3):
#
#   * a known (provider, uid) identity signs its user in;
#   * a signed-in user explicitly connects the external account to
#     themselves (never to anyone else);
#   * an unknown identity whose email matches an existing account is NOT
#     auto-merged — the owner must sign in with their credentials first and
#     link from settings;
#   * a genuinely new user is sent to the legal-assent interstitial, and no
#     account exists until they accept there.
class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def google_oauth2
    complete_oauth
  end

  def github
    complete_oauth
  end

  private

  def complete_oauth
    identity = Identity.find_by(provider: auth.provider, uid: auth.uid)

    if user_signed_in?
      connect_to_current_user(identity)
    elsif identity
      sign_in_identity(identity)
    else
      begin_signup_or_bounce
    end
  end

  def auth
    request.env["omniauth.auth"]
  end

  def provider_label
    Foundation::Oauth.label(auth.provider)
  end

  # Explicit connect, initiated from /settings/connections while signed in.
  # The user just proved control of the external account, so attach it —
  # unless somebody else already holds it.
  def connect_to_current_user(identity)
    if identity.nil?
      current_user.identities.create!(provider: auth.provider, uid: auth.uid)
      redirect_to settings_connections_path, notice: "#{provider_label} is now connected to your account."
    elsif identity.user == current_user
      redirect_to settings_connections_path, notice: "#{provider_label} was already connected."
    else
      redirect_to settings_connections_path,
        alert: "That #{provider_label} account is already connected to a different user."
    end
  end

  def sign_in_identity(identity)
    set_flash_message(:notice, :success, kind: provider_label) if is_navigational_format?
    sign_in_and_redirect identity.user, event: :authentication
  end

  def begin_signup_or_bounce
    email = auth.info.email.to_s.strip.downcase

    if email.blank?
      redirect_to new_user_session_path,
        alert: "#{provider_label} did not share an email address, so this sign-in cannot continue. " \
               "Make an email visible to the app on #{provider_label}, or use another method."
    elsif User.exists?(email: email)
      # SPEC M3.3: a matching email is NEVER silently merged — that would
      # let anyone who controls a same-address OAuth account take over the
      # local one. The owner signs in with their existing credentials, then
      # links explicitly from settings.
      redirect_to new_user_session_path,
        alert: "An account for #{email} already exists. Sign in with your existing credentials first; " \
               "you can then connect #{provider_label} from the Connections page."
    else
      session[Foundation::OauthSignupsController::SESSION_KEY] = {
        "provider" => auth.provider,
        "uid" => auth.uid,
        "email" => email,
        "expires_at" => Foundation::OauthSignupsController::PENDING_TTL.from_now.iso8601
      }
      redirect_to oauth_assent_path
    end
  end
end
