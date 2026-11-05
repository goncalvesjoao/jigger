class Collection < ApplicationRecord
  belongs_to :user
  has_many :collection_recipes, dependent: :destroy
  has_many :recipes, through: :collection_recipes

  validates :name, presence: true
  validates :visibility, inclusion: { in: %w[private public] }

  scope :readable_by, ->(user) { user ? where(visibility: "public").or(where(user: user)) : where(visibility: "public") }
end
