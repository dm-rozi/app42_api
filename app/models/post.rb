class Post < ApplicationRecord
  belongs_to :user
  has_many :ratings, dependent: :destroy

  validates :title, :body, :ip, presence: true
  validates :title, length: { minimum: 2, maximum: 255 }
  validates :body, length: { minimum: 2, maximum: 5000 }
end
