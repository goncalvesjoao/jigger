module CollectionPreviews
  private
    def load_collection_previews(collections, viewer:)
      memberships = CollectionRecipe.where(collection: collections).where(recipe_id: Recipe.readable_by(viewer).select(:id))
      @recipe_counts = memberships.group(:collection_id).count
      @previews = memberships.where(<<~SQL.squish).order(created_at: :desc, id: :desc).includes(recipe: { image_attachment: :blob }).group_by(&:collection_id)
        collection_recipes.id IN (
          SELECT preview.id FROM collection_recipes preview
          WHERE preview.collection_id = collection_recipes.collection_id
          ORDER BY preview.created_at DESC, preview.id DESC LIMIT 4
        )
      SQL
    end
end
