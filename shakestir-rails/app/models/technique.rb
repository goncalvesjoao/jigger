class Technique < ApplicationRecord
  include StoredName

  has_many :recipe_techniques, dependent: :restrict_with_error
  has_many :recipes, through: :recipe_techniques

  validates :slug, presence: true, uniqueness: true, format: { with: /\A[a-z0-9]+(?:-[a-z0-9]+)*\z/ }
  validates :name, :description, :instructions, presence: true

  def display_name
    name
  end

  def to_param
    slug
  end
end
