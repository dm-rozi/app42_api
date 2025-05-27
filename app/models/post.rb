require "resolv"

class Post < ApplicationRecord
  belongs_to :user
  has_many :ratings, dependent: :destroy

  validates :title, :body, :ip, presence: true
  validates :title, length: { minimum: 2, maximum: 255 }
  validates :body, length: { minimum: 2, maximum: 5000 }

  validates :ip, format: { with: Resolv::IPv4::Regex, message: "must be a valid IP address" }
end
