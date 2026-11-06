class RecipesController < ApplicationController
  include MarketplaceSearch

  allow_unauthenticated_access only: %i[ index show ]
  before_action :set_recipe, only: %i[ show edit update destroy ]

  before_action :authorize_recipe
  after_action :verify_authorized
  around_action :with_recipe_language, only: %i[ create edit update ]

  # GET /recipes or /recipes.json
  def index
    @pagination = matching_recipes.reorder(published_at: :desc, created_at: :desc, id: :desc)
      .page(params[:page]).per(24)
    @recipes = @pagination
  end

  # GET /recipes/1 or /recipes/1.json
  def show
    ActiveRecord::Associations::Preloader.new(records: [ @recipe ], associations: {
      recipe_ingredients: { ingredient: [ :translations, { image_attachment: :blob } ] },
      recipe_utensils: { utensil: [ :translations, { image_attachment: :blob } ] },
      techniques: :translations
    }).call
    if @recipe.cocktail && policy(@recipe.cocktail).show?
      @cocktail = @recipe.cocktail
      @related_recipes = Recipe.marketplace.where(cocktail: @cocktail)
        .where.not(id: @recipe.id).with_attached_image.includes(:translations, :user, cocktail: [ :translations, { image_attachment: :blob } ])
    end
  end

  # GET /recipes/new
  def new
    @recipe = Recipe.new(language: I18n.locale.to_s)
  end

  # GET /recipes/1/edit
  def edit
  end

  # POST /recipes or /recipes.json
  def create
    @recipe = Recipe.new(recipe_params)
    @recipe.user = Current.user

    respond_to do |format|
      if @recipe.save
        format.html { redirect_to @recipe, notice: "Recipe was successfully created." }
        format.json { render :show, status: :created, location: @recipe }
      else
        format.html { render :new, status: :unprocessable_content }
        format.json { render json: @recipe.errors, status: :unprocessable_content }
      end
    end
  end

  # PATCH/PUT /recipes/1 or /recipes/1.json
  def update
    respond_to do |format|
      if @recipe.update(recipe_params)
        format.html { redirect_to @recipe, notice: "Recipe was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @recipe }
      else
        format.html { render :edit, status: :unprocessable_content }
        format.json { render json: @recipe.errors, status: :unprocessable_content }
      end
    end
  end

  # DELETE /recipes/1 or /recipes/1.json
  def destroy
    @recipe.destroy!

    respond_to do |format|
      format.html { redirect_to recipes_path, notice: "Recipe was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    def with_recipe_language(&block)
      language = params.dig(:recipe, :language).presence || @recipe&.language
      locale = language.present? && language != "und" ? language : I18n.default_locale
      Globalize.with_locale(locale, &block)
    end

    # Use callbacks to share common setup or constraints between actions.
    def set_recipe
      @recipe = Recipe.find(params.expect(:id))
    end

    def authorize_recipe
      authorize @recipe || Recipe
    end

    # Only allow a list of trusted parameters through.
    def recipe_params
      fields = [ :name, :language, :steps, :preparation_time_seconds, :servings, :preparation_method, :source_reference, :source_url, :visibility, :publication_state, :image ]
      fields += [ :cocktail_id ] if Current.user&.admin?
      fields += [ { technique_ids: [] } ]
      permitted = params.expect(recipe: fields)
      if permitted[:image].blank?
        permitted.delete(:image)
      elsif !permitted[:image].is_a?(ActionDispatch::Http::UploadedFile)
        raise ActionController::BadRequest, "image must be an uploaded file"
      end
      permitted
    end
end
