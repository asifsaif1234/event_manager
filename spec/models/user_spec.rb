require 'rails_helper'

RSpec.describe User, type: :model do
  describe "associations" do
    it { should have_many(:votes).dependent(:destroy) }
    it { should have_many(:events).through(:votes) }
  end

  describe "validations" do
    subject { build(:user) }

    it { should validate_presence_of(:clerk_id) }
    it { should validate_uniqueness_of(:clerk_id) }
    it { should validate_presence_of(:email) }
  end

  describe "instance methods" do
    describe "#display_name" do
      it "returns first_name if present" do
        user = build(:user, first_name: "John", last_name: "Doe")
        expect(user.display_name).to eq("John")
      end

      it "returns the part of email before @ if first_name is blank" do
        user = build(:user, first_name: nil, email: "johndoe@example.com")
        expect(user.display_name).to eq("johndoe")
      end
    end
  end

  describe "class methods" do
    describe ".find_or_create_from_clerk" do
      let(:clerk_user) do
        instance_double(
          "ClerkUser",
          id: "clerk_123",
          email_addresses: [ instance_double("Email", email_address: "test@example.com") ],
          first_name: "John",
          last_name: "Doe",
          image_url: "https://example.com/avatar.jpg"
        )
      end

      it "creates a new user if one doesn't exist" do
        expect {
          User.find_or_create_from_clerk(clerk_user)
        }.to change(User, :count).by(1)

        user = User.last
        expect(user.clerk_id).to eq("clerk_123")
        expect(user.email).to eq("test@example.com")
        expect(user.first_name).to eq("John")
        expect(user.last_name).to eq("Doe")
        expect(user.avatar_url).to eq("https://example.com/avatar.jpg")
        expect(user.last_synced_at).to be_within(1.second).of(Time.current)
      end

      it "finds an existing user and updates attributes" do
        existing_user = create(:user, clerk_id: "clerk_123", email: "old@example.com")

        expect {
          User.find_or_create_from_clerk(clerk_user)
        }.to_not change(User, :count)

        existing_user.reload
        expect(existing_user.email).to eq("test@example.com")
        expect(existing_user.first_name).to eq("John")
        expect(existing_user.last_name).to eq("Doe")
        expect(existing_user.last_synced_at).to be_within(1.second).of(Time.current)
      end

      it "returns nil and logs error if saving fails" do
        allow_any_instance_of(User).to receive(:save!).and_raise(StandardError, "Some error")
        expect(Rails.logger).to receive(:error).with("Error syncing user: Some error")
        expect(User.find_or_create_from_clerk(clerk_user)).to be_nil
      end
    end
  end
end
