class Cocktail < ApplicationRecord
  belongs_to :user
  has_many :cocktail_ingredients, dependent: :destroy
  has_many :cocktail_users
end
