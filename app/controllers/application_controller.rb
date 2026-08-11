class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  # A failed (or missing) Turnstile response on a guarded form is almost
  # always a bot; for the rare human, send them back to retry the challenge.
  rescue_from RailsCloudflareTurnstile::Forbidden do
    redirect_back fallback_location: root_path,
      alert: "We could not verify you are human. Please complete the challenge and try again."
  end
end
