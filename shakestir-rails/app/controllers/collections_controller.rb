class CollectionsController < ApplicationController
  include CollectionPreviews

  allow_unauthenticated_access only: :show
  before_action :set_owned_collection, only: %i[edit update destroy]

  def index
    @collections = Current.user.collections.order(:created_at)
    load_collection_previews(@collections, viewer: Current.user)
  end

  def show
    resume_session
    @collection = Collection.readable_by(Current.user).find(params[:id])
    @recipes = @collection.recipes.merge(Recipe.readable_by(Current.user)).with_attached_image.includes(:recipe_steps).reorder("collection_recipes.created_at DESC, collection_recipes.id DESC").to_a
  end

  def new
    @collection = Current.user.collections.new
  end

  def create
    @collection = Current.user.collections.new(collection_params)
    if @collection.save
      redirect_to @collection, notice: "Collection created."
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit
  end

  def update
    if @collection.update(collection_params)
      redirect_to @collection, notice: "Collection updated.", status: :see_other
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    if @collection.destroy
      redirect_to my_collections_path, notice: "Collection deleted.", status: :see_other
    else
      redirect_to @collection, alert: "Favorites is your permanent private collection.", status: :see_other
    end
  end

  private
    def set_owned_collection
      @collection = Current.user.collections.find(params[:id])
    end

    def collection_params
      params.expect(collection: [ :name, :visibility ])
    end
end
