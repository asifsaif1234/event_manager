class SessionsController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [ :create ]

  def create
    if clerk.user.present?
      user = User.find_or_create_from_clerk(clerk.user)
      session[:user_id] = user.id
      redirect_to root_path, notice: "Welcome, #{user&.first_name}!"
    else
      redirect_to "/sign_in", alert: "Sign in failed. Please try again."
    end
  end

  def destroy
    revoke_clerk_session

    reset_session

    redirect_to root_path,
                notice: "Signed out successfully"
  end

  private

  def revoke_clerk_session
    clerk_session = clerk&.session
    return if clerk_session.blank?

    session_id = clerk_session["sid"]
    return if session_id.blank?

    require "net/http"

    uri = URI(
      "https://api.clerk.com/v1/sessions/#{session_id}/revoke"
    )

    request = Net::HTTP::Post.new(uri)

    request["Authorization"] =
      "Bearer #{ENV.fetch("CLERK_SECRET_KEY")}"

    Net::HTTP.start(
      uri.hostname,
      uri.port,
      use_ssl: true
    ) do |http|
      http.request(request)
    end
  end
end
