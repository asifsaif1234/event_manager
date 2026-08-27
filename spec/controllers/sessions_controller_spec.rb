# spec/controllers/sessions_controller_spec.rb
require "rails_helper"

RSpec.describe SessionsController, type: :controller do
  let(:user) { create(:user) }

  # --- Helper to mock Clerk (Use plain double) ---
  def mock_clerk(user: nil, session: nil)
    clerk = double("Clerk")
    allow(clerk).to receive(:user).and_return(user)
    allow(clerk).to receive(:session).and_return(session)
    allow(controller).to receive(:clerk).and_return(clerk)
  end

  describe "POST #create" do
    context "when Clerk user is present" do
      let(:clerk_user) do
        double(
          "ClerkUser",
          id: "clerk_123",
          email_addresses: [ double("Email", email_address: "user@example.com") ],
          first_name: "John",
          last_name: "Doe",
          image_url: "https://example.com/avatar.jpg"
        )
      end

      before do
        mock_clerk(user: clerk_user)
      end

      it "creates or finds the user and sets session" do
        allow(User).to receive(:find_or_create_from_clerk).and_return(user)

        post :create

        expect(session[:user_id]).to eq(user.id)
        expect(response).to redirect_to(root_path)
        expect(flash[:notice]).to match(/Welcome/i)
      end

      it "calls User.find_or_create_from_clerk" do
        expect(User).to receive(:find_or_create_from_clerk).with(clerk_user).and_return(user)
        post :create
      end
    end

    context "when Clerk user is not present" do
      before do
        mock_clerk(user: nil)
      end

      it "redirects to sign_in with alert" do
        post :create

        expect(response).to redirect_to("/sign_in")
        expect(flash[:alert]).to match(/failed/i)
      end
    end
  end

  describe "DELETE #destroy" do
    context "when Clerk session is present" do
      let(:clerk_session) { { "sid" => "session_123" } }

      before do
        mock_clerk(session: clerk_session)
      end

      it "revokes the Clerk session via API" do
        # Mock Net::HTTP
        http = instance_double(Net::HTTP)
        request = instance_double(Net::HTTP::Post)

        allow(Net::HTTP).to receive(:start).and_yield(http)
        allow(Net::HTTP::Post).to receive(:new).and_return(request)
        allow(request).to receive(:[]=)
        allow(http).to receive(:request).with(request)

        delete :destroy

        expect(Net::HTTP::Post).to have_received(:new).with(
          URI("https://api.clerk.com/v1/sessions/session_123/revoke")
        )
        expect(request).to have_received(:[]=).with("Authorization", "Bearer #{ENV['CLERK_SECRET_KEY']}")
        expect(http).to have_received(:request).with(request)
      end

      it "redirects to root_path with notice" do
        allow(Net::HTTP).to receive(:start).and_return(nil)

        delete :destroy

        expect(response).to redirect_to(root_path)
        expect(flash[:notice]).to match(/Signed out/i)
      end
    end

    context "when Clerk session is not present" do
      before do
        mock_clerk(session: nil)
      end

      it "redirects to root_path without calling API" do
        expect(Net::HTTP).not_to receive(:start)

        delete :destroy

        expect(response).to redirect_to(root_path)
        expect(flash[:notice]).to match(/Signed out/i)
      end
    end
  end
end
