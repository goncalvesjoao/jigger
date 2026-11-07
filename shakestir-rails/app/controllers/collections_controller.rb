class CollectionsController < ApplicationController
  include CollectionPreviews

  allow_unauthenticated_access only: :show
  before_action :set_owned_collection, only: %i[edit update destroy]
  before_action :prevent_collection_caching, only: %i[index show create update destroy]

  def index
    @collections = Current.user.collections.includes(:user).order(:created_at)
    load_collection_previews(@collections, viewer: Current.user)
  end

  def show
    resume_session
    @collection = Collection.readable_by(Current.user).find(params[:id])
    load_collection_recipes
  end

  def new
    @collection = Current.user.collections.new
  end

  def create
    @collection = Current.user.collections.new(collection_params)
    if @collection.save
      respond_to do |format|
        format.html { redirect_to @collection, notice: "Collection created." }
        format.json do
          load_collection_recipes
          render :show, status: :created, location: collection_url(@collection, format: :json)
        end
      end
    else
      render_collection_errors(:new)
    end
  end

  def edit
  end

  def update
    if @collection.update(collection_params)
      respond_to do |format|
        format.html { redirect_to @collection, notice: "Collection updated.", status: :see_other }
        format.json do
          load_collection_recipes
          render :show
        end
      end
    else
      render_collection_errors(:edit)
    end
  end

  def destroy
    if @collection.destroy
      respond_to do |format|
        format.html { redirect_to my_collections_path, notice: "Collection deleted.", status: :see_other }
        format.json { head :no_content }
      end
    else
      respond_to do |format|
        format.html { redirect_to @collection, alert: "Favorites is your permanent private collection.", status: :see_other }
        format.json do
          @collection.errors.add(:base, "Favorites is your permanent private collection.") if @collection.system_key == "favorites"
          @collection.errors.add(:base, "Collection could not be deleted.") if @collection.errors.empty?
          render json: { errors: @collection.errors.to_hash }, status: :unprocessable_content
        end
      end
    end
  end

  private
    def load_collection_recipes
      @recipes = @collection.recipes.merge(Recipe.readable_by(Current.user)).with_attached_image
        .includes(:recipe_steps, :techniques, :user, cocktail: { image_attachment: :blob })
        .reorder("collection_recipes.created_at DESC, collection_recipes.id DESC").to_a
    end

    def render_collection_errors(template)
      respond_to do |format|
        format.html { render template, status: :unprocessable_content }
        format.json { render json: { errors: @collection.errors.to_hash }, status: :unprocessable_content }
      end
    end

    def prevent_collection_caching
      response.headers["Cache-Control"] = "private, no-store" if request.format.json?
    end

    def set_owned_collection
      @collection = Current.user.collections.find(params[:id])
    end

    def collection_params
      params.expect(collection: [ :name, :visibility ])
    end
end
