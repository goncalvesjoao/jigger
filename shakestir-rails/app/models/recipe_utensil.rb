class RecipeUtensil < ApplicationRecord
  enum :role, {
    preparation: "preparation",
    serving: "serving"
  }, validate: true

  belongs_to :recipe
  belongs_to :utensil

  validates :submitted_text, presence: true
  validates :utensil_id, uniqueness: { scope: :recipe_id }
end
