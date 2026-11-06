class CollectionRecipe < ApplicationRecord
  belongs_to :collection
  belongs_to :recipe

  validates :recipe_id, uniqueness: { scope: :collection_id }
  validate :membership_identity_cannot_change, on: :update

  # Ordinary collection saves are not stars. Keep this conditional counter in
  # the membership transaction, using atomic SQL updates rather than read/write.
  after_create :increment_stars_count, if: :favorite?

  private
    def favorite?
      collection.system_key == "favorites"
    end

    def increment_stars_count
      Recipe.increment_counter(:stars_count, recipe_id)
    end

    # Like Active Record's own counter cache, decrement only when a row was
    # actually deleted, including when two requests destroy the same membership.
    def destroy_row
      affected_rows = super
      Recipe.decrement_counter(:stars_count, recipe_id) if affected_rows > 0 && favorite?
      affected_rows
    end

    def membership_identity_cannot_change
      if will_save_change_to_recipe_id? || will_save_change_to_collection_id?
        errors.add(:base, "Remove and recreate a membership to move it")
      end
    end
end
