class CollectionsController < ApplicationController
  allow_unauthenticated_access only: :show
  before_action :set_owned_collection, only: %i[edit update destroy]

  def index
    @collections = Current.user.collections.order(:created_at)
  end

  def show
    resume_session
    @collection = Collection.readable_by(Current.user).find(params[:id])
    @recipes = @collection.recipes.merge(Recipe.readable_by(Current.user)).with_attached_image.includes(:translations, :recipe_steps)
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
