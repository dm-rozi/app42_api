require 'rails_helper'

RSpec.describe Post, type: :model do
  let(:user) { User.create!(login: "tester") }

  describe "validations" do
    it "is valid with valid attributes" do
      post = Post.new(title: "Hi", body: "Content", ip: "127.0.0.1", user: user)
      expect(post).to be_valid
    end

    it "is invalid without a title" do
      post = Post.new(title: nil, body: "Text", ip: "127.0.0.1", user: user)
      expect(post).not_to be_valid
      expect(post.errors[:title]).to include("can't be blank")
    end

    it "is invalid if title is too short" do
      post = Post.new(title: "A", body: "Text", ip: "127.0.0.1", user: user)
      expect(post).not_to be_valid
      expect(post.errors[:title]).to include("is too short (minimum is 2 characters)")
    end

    it "is invalid if title is too long" do
      post = Post.new(title: "a" * 256, body: "Text", ip: "127.0.0.1", user: user)
      expect(post).not_to be_valid
      expect(post.errors[:title]).to include("is too long (maximum is 255 characters)")
    end

    it "is invalid if body is too short" do
      post = Post.new(title: "Title", body: "A", ip: "127.0.0.1", user: user)
      expect(post).not_to be_valid
      expect(post.errors[:body]).to include("is too short (minimum is 2 characters)")
    end

    it "is invalid if body is too long" do
      post = Post.new(title: "Title", body: "a" * 5001, ip: "127.0.0.1", user: user)
      expect(post).not_to be_valid
      expect(post.errors[:body]).to include("is too long (maximum is 5000 characters)")
    end

    it "is invalid without an ip" do
      post = Post.new(title: "Title", body: "Text", ip: nil, user: user)
      expect(post).not_to be_valid
      expect(post.errors[:ip]).to include("can't be blank")
    end
  end

  describe "associations" do
    it "belongs to user" do
      post = Post.new(title: "T", body: "B", ip: "127.0.0.1")
      expect { post.user }.not_to raise_error
    end

    it "has many ratings and destroys them when post is destroyed" do
      post = Post.create!(title: "Title", body: "Body", ip: "127.0.0.1", user: user)
      post.ratings.create!(user: user, value: 5)
      expect { post.destroy }.to change { Rating.count }.by(-1)
    end
  end
end
