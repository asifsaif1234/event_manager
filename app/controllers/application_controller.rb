class ApplicationController < ActionController::Base
  include Clerk::Authenticatable

  helper_method :current_user, :user_signed_in?
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  def authenticate_user!
    unless user_signed_in?
      session[:return_to] = request.fullpath
      redirect_to root_path, alert: "Please sign in to vote." and return
    end
  end

  def current_user
    @current_user ||= begin
      if clerk.user.present?
        user = User.find_or_create_from_clerk(clerk.user)
        session[:user_id] = user.id
        user
      elsif session[:user_id].present?
        User.find_by(id: session[:user_id])
      end
    end
  end

  def user_signed_in?
    current_user.present?
  end

  def sign_in_path
    ENV["CLERK_SIGN_IN_URL"] || "/sign_in"
  end

  def sign_up_path
    ENV["CLERK_SIGN_UP_URL"] || "/sign_up"
  end
end
