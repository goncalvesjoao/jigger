class CollectionsController < ApplicationController
  allow_unauthenticated_access only: :show
  before_action :set_owned_collection, only: %i[edit update destroy]

  def index
    @collections = Current.user.collections.order(:created_at)
    memberships = CollectionRecipe.where(collection: @collections).where(recipe_id: Recipe.readable_by(Current.user).select(:id))
    @recipe_counts = memberships.group(:collection_id).count
    @previews = memberships.where(<<~SQL.squish).order(created_at: :desc, id: :desc).includes(recipe: { image_attachment: :blob }).group_by(&:collection_id)
      collection_recipes.id IN (
        SELECT preview.id FROM collection_recipes preview
        WHERE preview.collection_id = collection_recipes.collection_id
        ORDER BY preview.created_at DESC, preview.id DESC LIMIT 4
      )
    SQL
  end

  def show
    resume_session
    @collection = Collection.readable_by(Current.user).find(params[:id])
    @recipes = @collection.recipes.merge(Recipe.readable_by(Current.user)).with_attached_image.includes(:translations, :recipe_steps).reorder("collection_recipes.created_at DESC, collection_recipes.id DESC").to_a
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
    @collection.destroy!
    redirect_to my_collections_path, notice: "Collection deleted.", status: :see_other
  end

  private
    def set_owned_collection
      @collection = Current.user.collections.find(params[:id])
    end

    def collection_params
      params.expect(collection: [ :name, :visibility ])
    end
end
