require 'rails_helper'

RSpec.describe "GET /api/v1/posts/shared_ips", type: :request do
  before do
    shared_ips = [ "127.0.0.1", "127.0.0.2", "127.0.0.3" ]

    shared_ips.each do |ip|
      2.times do
        user = User.create!(login: Faker::Internet.unique.username(specifier: 4..5))
        Post.create!(title: "Title", body: "Body", ip: ip, user: user)
      end
    end

    user = User.create!(login: "solo_user")
    Post.create!(title: "Title", body: "Body", ip: "192.168.1.1", user: user)
  end

  it "returns shared IPs with multiple authors" do
    get "/api/v1/posts/shared_ips"

    expect(response).to have_http_status(:ok)
    json = JSON.parse(response.body)

    expect(json["data"]).to all(include("ip", "logins"))
    expect(json["data"].size).to eq(3)
    expect(json["data"].map { |r| r["logins"].uniq.size }).to all(be > 1)
  end

  it "respects pagination with limit and next_page" do
    get "/api/v1/posts/shared_ips", params: { limit: 2, page: 1 }

    expect(response).to have_http_status(:ok)
    json = JSON.parse(response.body)

    expect(json["data"].size).to eq(2)
    expect(json["page_info"]).to eq({
      "page" => 1,
      "limit" => 2,
      "has_next_page" => true
    })
  end

  it "returns next_page: false when on last page" do
    get "/api/v1/posts/shared_ips", params: { limit: 2, page: 2 }

    expect(response).to have_http_status(:ok)
    json = JSON.parse(response.body)

    expect(json["data"].size).to eq(1)
    expect(json["page_info"]["has_next_page"]).to eq(false)
  end

  it "returns error if limit exceeds max" do
    get "/api/v1/posts/shared_ips", params: { limit: 999 }

    expect(response).to have_http_status(:bad_request)
    expect(JSON.parse(response.body)).to include("errors")
  end
end
