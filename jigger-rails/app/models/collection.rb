class Collection < ApplicationRecord
  belongs_to :user
  has_many :collection_recipes, dependent: :destroy
  has_many :recipes, through: :collection_recipes

  validates :name, presence: true
  validates :visibility, inclusion: { in: %w[private public] }

  validates :visibility, inclusion: { in: %w[private] }, if: -> { system_key == "favorites" }
  before_destroy :preserve_favorites

  private def preserve_favorites
    throw :abort if system_key == "favorites" && !destroyed_by_association
  end

  scope :readable_by, ->(user) { user ? where(visibility: "public").or(where(user: user)) : where(visibility: "public") }
end
