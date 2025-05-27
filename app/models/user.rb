class User < ApplicationRecord
  has_many :posts, dependent: :destroy
  has_many :ratings, dependent: :destroy

  validates :login, presence: true, length: { minimum: 4, maximum: 50 }, uniqueness: true
end
