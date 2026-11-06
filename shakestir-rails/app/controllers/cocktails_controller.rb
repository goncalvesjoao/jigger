class CocktailsController < ApplicationController
  include MarketplaceSearch

  allow_unauthenticated_access only: %i[index show]
  before_action :set_cocktail, only: :show
  before_action { authorize @cocktail || Cocktail }
  after_action :verify_authorized

  def index
    cocktails = Cocktail.all
    cocktails = cocktails.where(id: Recipe.marketplace.select(:cocktail_id)) unless Current.user&.admin?
    @pagination = cocktails.search(params[:q]).order(:id)
      .with_attached_image.includes(:translations).page(params[:page]).per(24)
  end

  def show
    @recipes = matching_recipes.where(cocktail: @cocktail)
    @filtered = params[:q].present? || makeable_filter? || Array(params[:ingredient_ids]).reject(&:blank?).any? || Array(params[:utensil_ids]).reject(&:blank?).any?
    if @filtered
      @other_recipes = Recipe.marketplace.where(cocktail: @cocktail)
        .where.not(id: @recipes.except(:includes, :order).select(:id))
        .with_attached_image.includes(:translations, :user, cocktail: [ :translations, { image_attachment: :blob } ])
      if params.key?(:ingredient_ids) || params.key?(:utensil_ids)
        @available_ingredients = Ingredient.usable.where(id: Array(params[:ingredient_ids]).reject(&:blank?)).includes(:translations)
        @available_utensils = Utensil.usable.where(id: Array(params[:utensil_ids]).reject(&:blank?)).includes(:translations)
      end
    end
  end

  private
    def set_cocktail
      @cocktail = Cocktail.find(params.expect(:id))
    end
end
