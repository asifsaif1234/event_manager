class TestSessionsController < ApplicationController
  skip_before_action :require_clerk_session!, raise: false

  def create
    user = User.find(params[:user_id])

    reset_session
    session[:user_id] = user.id

    redirect_to events_path
  end

  def destroy
    reset_session

    redirect_to events_path
  end
end
