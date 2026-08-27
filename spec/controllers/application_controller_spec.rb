require 'rails_helper'

RSpec.describe ApplicationController, type: :controller do
  controller do
    def index
      render plain: "ok"
    end

    def protected_action
      authenticate_user!
      return if performed?
      render plain: "protected"
    end
  end

  before do
    routes.draw do
      get 'index' => 'anonymous#index'
      get 'protected' => 'anonymous#protected_action'
    end
  end

  let(:clerk_user_data) do
    double(
      'ClerkUser',
      id: 'user_clerk_123',
      email_addresses: [ double(email_address: 'test@example.com') ],
      first_name: 'Test',
      last_name: 'User'
    )
  end

  let(:user) { create(:user, clerk_id: 'user_clerk_123', email: 'test@example.com') }

  describe "#current_user" do
    context "when clerk.user is present" do
      before do
        allow(controller).to receive(:clerk).and_return(
          double(user: clerk_user_data)
        )
        allow(User).to receive(:find_or_create_from_clerk)
          .with(clerk_user_data)
          .and_return(user)
      end

      it "returns the user created/found from Clerk" do
        expect(controller.current_user).to eq(user)
      end

      it "stores the user id in the session" do
        controller.current_user
        expect(session[:user_id]).to eq(user.id)
      end
    end

    context "when clerk.user is blank but session[:user_id] is present" do
      before do
        allow(controller).to receive(:clerk).and_return(double(user: nil))
        session[:user_id] = user.id
      end

      it "returns the user from the session" do
        expect(controller.current_user).to eq(user)
      end
    end

    context "when neither clerk.user nor session[:user_id] is present" do
      before do
        allow(controller).to receive(:clerk).and_return(double(user: nil))
        session[:user_id] = nil
      end

      it "returns nil" do
        expect(controller.current_user).to be_nil
      end
    end

    it "memoizes the result" do
      allow(controller).to receive(:clerk).and_return(double(user: nil))
      session[:user_id] = user.id

      expect(User).to receive(:find_by).with(id: user.id).once.and_return(user)

      2.times { controller.current_user }
    end
  end

  describe "#user_signed_in?" do
    it "returns true when current_user is present" do
      allow(controller).to receive(:current_user).and_return(user)
      expect(controller.user_signed_in?).to be true
    end

    it "returns false when current_user is nil" do
      allow(controller).to receive(:current_user).and_return(nil)
      expect(controller.user_signed_in?).to be false
    end
  end

  describe "#authenticate_user!" do
    context 'when the user is signed in' do
      before do
        allow(controller).to receive(:user_signed_in?).and_return(true)
      end

      it "does not redirect" do
        get :protected_action
        expect(response).to have_http_status(:ok)
        expect(response.body).to eq('protected')
      end
    end

    context "when the user is not signed in" do
      before do
        allow(controller).to receive(:user_signed_in?).and_return(false)
      end

      it "stores the current path in the session" do
        get :protected_action
        expect(session[:return_to]).to eq('/protected')
      end

      it "redirects to root_path with an alert" do
        get :protected_action
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq('Please sign in to vote.')
      end
    end
  end

  describe "#sign_in_path" do
    it "returns the ENV value when present" do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with('CLERK_SIGN_IN_URL')
        .and_return('https://clerk.example.com/sign-in')

      expect(controller.sign_in_path).to eq('https://clerk.example.com/sign-in')
    end

    it "falls back to /sign_in" do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with('CLERK_SIGN_IN_URL').and_return(nil)

      expect(controller.sign_in_path).to eq('/sign_in')
    end
  end

  describe "#sign_up_path" do
    it "returns the ENV value when present" do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with('CLERK_SIGN_UP_URL')
        .and_return('https://clerk.example.com/sign-up')

      expect(controller.sign_up_path).to eq('https://clerk.example.com/sign-up')
    end

    it "falls back to /sign_up" do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with('CLERK_SIGN_UP_URL').and_return(nil)

      expect(controller.sign_up_path).to eq('/sign_up')
    end
  end
end
