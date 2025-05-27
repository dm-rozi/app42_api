require 'rails_helper'

RSpec.describe User, type: :model do
  it "is valid with a login between 4 and 5 characters" do
    expect(described_class.new(login: "abcd")).to be_valid
    expect(described_class.new(login: "abcde")).to be_valid
  end

  it "is invalid without a login" do
    user = described_class.new(login: nil)
    expect(user).to be_invalid
    expect(user.errors[:login]).to include("can't be blank")
  end

  it "is invalid if login is too short" do
    user = described_class.new(login: "abc")
    user.validate
    expect(user.errors[:login]).to include("is too short (minimum is 4 characters)")
  end

  it "is invalid if login is too long" do
    user = described_class.new(login: "abcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyz")
    user.validate
    expect(user.errors[:login]).to include("is too long (maximum is 50 characters)")
  end
end
