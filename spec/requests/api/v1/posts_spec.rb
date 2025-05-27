require 'rails_helper'

RSpec.describe "POST /api/v1/posts", type: :request do
  let(:valid_params) do
    {
      login: "test_user",
      title: "A test post",
      body: "Post content here",
      ip: "95.216.191.138"
    }
  end

  it "creates a new user and post" do
    post "/api/v1/posts", params: valid_params

    expect(response).to have_http_status(:created)
    json = JSON.parse(response.body)
    expect(json["data"]["post"]["title"]).to eq("A test post")
    expect(json["data"]["user"]["login"]).to eq("test_user")
  end

  it "returns error for invalid user (missing login)" do
    post "/api/v1/posts", params: valid_params.except(:login)

    expect(response).to have_http_status(:unprocessable_entity)
    json = JSON.parse(response.body)
    expect(json["errors"]).to include("Login can't be blank")
  end

  it "uses existing user if login matches" do
    User.create!(login: "test_user")
    post "/api/v1/posts", params: valid_params

    expect(response).to have_http_status(:created)
    json = JSON.parse(response.body)
    expect(json["data"]["user"]["login"]).to eq("test_user")
  end

  it "returns error for invalid post (missing title)" do
    post "/api/v1/posts", params: valid_params.merge(title: "")

    expect(response).to have_http_status(:unprocessable_entity)
    json = JSON.parse(response.body)
    expect(json["errors"]).to include("Title can't be blank")
  end
end
