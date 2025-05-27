require 'rails_helper'

RSpec.describe Rating, type: :model do
  let(:user) { User.create!(login: "tester") }
  let(:post_record) { Post.create!(title: "Hello", body: "Some content", ip: "127.0.0.1", user: user) }

  describe "validations" do
    it "is valid with value between 1 and 5" do
      rating = Rating.new(user: user, post: post_record, value: 3)
      expect(rating).to be_valid
    end

    it "is invalid without value" do
      rating = Rating.new(user: user, post: post_record, value: nil)
      expect(rating).not_to be_valid
      expect(rating.errors[:value]).to include("can't be blank")
    end

    it "is invalid if value is less than 1" do
      rating = Rating.new(user: user, post: post_record, value: 0)
      expect(rating).not_to be_valid
      expect(rating.errors[:value]).to include("is not included in the list")
    end

    it "is invalid if value is greater than 5" do
      rating = Rating.new(user: user, post: post_record, value: 6)
      expect(rating).not_to be_valid
      expect(rating.errors[:value]).to include("is not included in the list")
    end

    it "is invalid if the same user rates the same post twice" do
      Rating.create!(user: user, post: post_record, value: 4)
      second_rating = Rating.new(user: user, post: post_record, value: 5)

      expect(second_rating).not_to be_valid
      expect(second_rating.errors[:user_id]).to include("has already been taken")
    end
  end
end
