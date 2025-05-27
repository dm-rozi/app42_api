class Post < ApplicationRecord
  belongs_to :user
  has_many :ratings, dependent: :destroy

  validates :title, :body, :ip, presence: true
  validates :title, length: { maximum: 255 }
  validates :body, length: { maximum: 5000 }
end
