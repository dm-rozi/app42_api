require "rails_helper"

RSpec.describe "GET /api/v1/posts/top", type: :request do
  let(:user) { User.create!(login: "tester") }

  before do
    post1 = Post.create!(title: "Post 1", body: "Body", ip: "127.0.0.1", user: user)
    post2 = Post.create!(title: "Post 2", body: "Body", ip: "127.0.0.2", user: user)
    post3 = Post.create!(title: "Post 3", body: "Body", ip: "127.0.0.3", user: user)

    Rating.create!(post: post1, user: user, value: 5)
    Rating.create!(post: post2, user: user, value: 3)
    Rating.create!(post: post3, user: user, value: 4)
  end

  it "returns top N posts ordered by average rating" do
    get "/api/v1/posts/top", params: { limit: 2 }

    expect(response).to have_http_status(:ok)
    json = JSON.parse(response.body)

    expect(json["data"].size).to eq(2)
    titles = json["data"].map { |p| p["title"] }
    expect(titles).to eq([ "Post 1", "Post 3" ])
  end

  it "returns error when limits greater than 250 posts" do
    get "/api/v1/posts/top", params: { limit: 999 }
    json = JSON.parse(response.body)

    expect(response).to have_http_status(:bad_request)
    expect(json["errors"]).to include("Limit cannot exceed 250")
  end
end
