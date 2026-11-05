class AccountController < ApplicationController
  def recipes
    owned_recipes = Current.user.recipes
    @recipe_counts = owned_recipes.group(:publication_state).count
    @publication_state = params[:state].presence_in(%w[draft published])
    @recipes = owned_recipes.search(params[:q])
    @recipes = @recipes.where(publication_state: @publication_state) if @publication_state
    @recipes = @recipes.with_attached_image.includes(:translations, :recipe_steps).order(updated_at: :desc, id: :desc)
  end
end
