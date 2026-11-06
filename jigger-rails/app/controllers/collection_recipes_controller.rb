class CollectionRecipesController < ApplicationController
  include RecipeStarring

  def create
    recipe = Recipe.readable_by(Current.user).find(params[:recipe_id])
    collection = nil
    Collection.transaction do
      collection = if params[:new_collection].present?
        Current.user.collections.create!(params.expect(new_collection: [ :name, :visibility ]))
      else
        Current.user.collections.find(params[:collection_id])
      end
      collection.collection_recipes.find_or_create_by!(recipe: recipe)
    end
    respond_to do |format|
      format.html { redirect_to collection, notice: "Recipe added to collection.", status: :see_other }
      format.json { render json: { id: collection.id, name: collection.name, visibility: collection.visibility, saved: true }.merge(recipe_star_payload(recipe)) }
    end
  rescue ActiveRecord::RecordInvalid => error
    respond_to do |format|
      format.html { redirect_to my_collections_path, alert: error.record.errors.full_messages.to_sentence }
      format.json { render json: { error: error.record.errors.full_messages.to_sentence }, status: :unprocessable_content }
    end
  end

  def destroy
    collection = Current.user.collections.find(params[:collection_id])
    collection.collection_recipes.find_by(recipe_id: params[:id])&.destroy!
    recipe = Recipe.readable_by(Current.user).find_by(id: params[:id])
    respond_to do |format|
      format.html { redirect_to collection, notice: "Recipe removed from collection.", status: :see_other }
      format.json { render json: { id: collection.id, name: collection.name, visibility: collection.visibility, saved: false }.merge(recipe ? recipe_star_payload(recipe) : {}) }
    end
  end
end
