class RecipesController < ApplicationController
  include MarketplaceSearch

  allow_unauthenticated_access only: %i[ index show ]
  before_action :set_recipe, only: %i[ show edit update destroy ]
  before_action only: %i[index show] do
    response.headers["Cache-Control"] = "private, no-store" if request.format.json?
  end

  before_action :authorize_recipe
  after_action :verify_authorized

  # GET /recipes or /recipes.json
  def index
    @pagination = matching_recipes.reorder(published_at: :desc, created_at: :desc, id: :desc)
      .page(params[:page]).per(24)
    @recipes = @pagination
  end

  # GET /recipes/1 or /recipes/1.json
  def show
    ActiveRecord::Associations::Preloader.new(records: [ @recipe ], associations: {
      recipe_ingredients: { ingredient: { image_attachment: :blob } },
      recipe_utensils: { utensil: { image_attachment: :blob } },
      techniques: {}
    }).call
    if @recipe.cocktail && policy(@recipe.cocktail).show?
      @cocktail = @recipe.cocktail
      @related_recipes = Recipe.marketplace.where(cocktail: @cocktail)
        .where.not(id: @recipe.id).with_attached_image.includes(:user, cocktail: { image_attachment: :blob })
    end
  end

  # GET /recipes/new
  def new
    @recipe = Recipe.new
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
        format.json { render_json_errors(@recipe.errors.to_hash, status: :unprocessable_content) }
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
        format.json { render_json_errors(@recipe.errors.to_hash, status: :unprocessable_content) }
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
    # Use callbacks to share common setup or constraints between actions.
    def set_recipe
      @recipe = Recipe.find(params.expect(:id))
    end

    def authorize_recipe
      authorize @recipe || Recipe
    end

    # Only allow a list of trusted parameters through.
    def recipe_params
      fields = [ :name, :steps, :servings, :source_reference, :source_url, :visibility, :publication_state, :image ]
      fields += [ :sweetness, :sourness, :bitterness, { technique_ids: [],
        recipe_ingredients_attributes: [ :id, :ingredient_id, :submitted_text, :quantity, :measuring_unit, :position, :optional, :role, :preparation_note, :_destroy ],
        recipe_utensils_attributes: [ :id, :utensil_id, :submitted_text, :role, :_destroy ],
        recipe_steps_attributes: [ :id, :position, :body, :_destroy ] } ]
      permitted = params.require(:recipe).permit(*fields)
      if permitted[:image].blank?
        permitted.delete(:image)
      elsif !permitted[:image].is_a?(ActionDispatch::Http::UploadedFile)
        raise ActionController::BadRequest, "image must be an uploaded file"
      end
      permitted
    end
end
