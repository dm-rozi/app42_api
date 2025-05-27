class Rating < ApplicationRecord
  belongs_to :user
  belongs_to :post

  validates :value, presence: true, inclusion: { in: 1..5 }
  validates :user_id, uniqueness: { scope: :post_id }
end
