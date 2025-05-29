require 'rails_helper'

RSpec.describe "POST /api/v1/posts/:post_id/ratings", type: :request do
  let(:user) { User.create!(login: "tester") }
  let(:post_record) { Post.create!(title: "Title", body: "Body", ip: "95.216.191.138", user: user) }

  describe "rating a post" do
    it "creates a rating and returns average" do
      post "/api/v1/posts/#{post_record.id}/ratings", params: {
        user_id: user.id,
        value: 5
      }

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["data"]["average_rating"]).to eq(5.0)
    end

    it "returns error when post not found" do
      post "/api/v1/posts/99999/ratings", params: {
        user_id: user.id,
        value: 5
      }

      expect(response).to have_http_status(:not_found)
      expect(JSON.parse(response.body)["errors"]).to include("Post not found")
    end

    it "returns error when user not found" do
      post "/api/v1/posts/#{post_record.id}/ratings", params: {
        user_id: 99999,
        value: 5
      }

      expect(response).to have_http_status(:not_found)
      expect(JSON.parse(response.body)["errors"]).to include("User not found")
    end

    it "returns error when rating is invalid" do
      post "/api/v1/posts/#{post_record.id}/ratings", params: {
        user_id: user.id,
        value: 10
      }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)["errors"]).to include("Rating must be between 1 and 5")
    end

    it "returns error if user already rated the post" do
      Rating.create!(post: post_record, user: user, value: 4)

      post "/api/v1/posts/#{post_record.id}/ratings", params: {
        user_id: user.id,
        value: 3
      }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)["errors"]).to include("User has already rated this post")
    end
  end
end
