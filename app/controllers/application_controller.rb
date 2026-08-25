class ApplicationController < ActionController::Base
  include Clerk::Authenticatable

  helper_method :current_user, :user_signed_in?
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

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
    "/sign_in"
  end

  def sign_up_path
    "/sign_up"
  end

  def sign_out_path
    "/sign_out"
  end
end
