class ProfilesController < ApplicationController
  include CollectionPreviews

  allow_unauthenticated_access only: :show
  before_action -> { require_authentication }, only: :show, if: -> { params[:id].blank? }

  def show
    resume_session
    @profile = params[:id].present? ? User.find(params[:id]) : Current.user
    @owned = @profile == Current.user
    raise ActiveRecord::RecordNotFound unless @owned || @profile.public_profile?

    @collections = @profile.collections.order(created_at: :desc)
    @recipes = @profile.recipes
    unless @owned
      @collections = @collections.where(visibility: "public")
      @recipes = @recipes.merge(Recipe.marketplace)
    end
    @recipes = @recipes.with_attached_image.includes(:translations, :recipe_steps).reorder(updated_at: :desc, id: :desc)
    load_collection_previews(@collections, viewer: @owned ? Current.user : nil)
  end

  def edit
    @profile = Current.user
  end

  def update
    @profile = Current.user
    if @profile.update(params.expect(user: [ :handle, :display_name, :bio, :profile_visibility ]))
      redirect_to my_profile_path, notice: "Profile updated.", status: :see_other
    else
      render :edit, status: :unprocessable_content
    end
  end
end
