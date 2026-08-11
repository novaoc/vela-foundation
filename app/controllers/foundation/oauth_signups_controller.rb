# Interstitial legal-assent step for first-time OAuth users (SPEC M3.3).
# The callback controller parks the provider payload in the session and
# sends the visitor here; nothing is written to the database until they
# accept, and declining (or walking away for PENDING_TTL) leaves no trace.
class Foundation::OauthSignupsController < ApplicationController
  # Session slot holding the pending OAuth payload: provider, uid, email,
  # and an expiry timestamp. Deliberately excludes provider tokens.
  SESSION_KEY = "foundation_pending_oauth"
  PENDING_TTL = 30.minutes

  before_action :load_pending_oauth, only: [ :new, :create ]

  def new
    @user = User.new(email: @pending["email"])
  end

  def create
    @user = build_user

    if @user.save
      LegalAcceptance.record!(user: @user, request: request, context: "oauth_signup")
      session.delete(SESSION_KEY)
      sign_in(@user)
      redirect_to root_path, notice: "Welcome! Your account is ready."
    else
      render :new, status: :unprocessable_content
    end
  end

  # Declining assent abandons the signup entirely.
  def destroy
    session.delete(SESSION_KEY)
    redirect_to new_user_session_path, notice: "Sign-up canceled. No account was created."
  end

  private

  def load_pending_oauth
    @pending = session[SESSION_KEY]
    return if pending_usable?

    session.delete(SESSION_KEY)
    redirect_to new_user_session_path,
      alert: "There is no sign-up in progress. Please start again."
  end

  def pending_usable?
    @pending.present? && Time.iso8601(@pending["expires_at"].to_s).future?
  rescue ArgumentError
    false
  end

  def build_user
    user = User.new(email: @pending["email"], legal_assent: params[:legal_assent])
    user.identities.build(provider: @pending["provider"], uid: @pending["uid"])
    # The provider already verified this address (SPEC M3.3), so the account
    # starts confirmed and no confirmation email goes out.
    user.skip_confirmation!
    user
  end
end
