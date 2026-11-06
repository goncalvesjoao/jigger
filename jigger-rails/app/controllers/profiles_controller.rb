class ProfilesController < ApplicationController
  include CollectionPreviews

  allow_unauthenticated_access only: :show
  before_action -> { require_authentication }, only: :show, if: -> { params[:id].blank? }

  def show
    resume_session
    @profile = params[:id].present? ? User.find(params[:id]) : Current.user
    @owned = @profile == Current.user
    @collections = @profile.collections.where(visibility: "public").order(created_at: :desc)
    @recipes = @profile.recipes.merge(Recipe.marketplace).with_attached_image
      .includes(:translations, :recipe_steps, :user, cocktail: [ :translations, { image_attachment: :blob } ])
      .reorder(updated_at: :desc, id: :desc)
    load_collection_previews(@collections, viewer: nil)
  end

  def edit
    @profile = Current.user
  end

  def update
    @profile = Current.user
    attributes = params.expect(user: [ :handle, :display_name, :bio, :image, :remove_image ])
    remove_image = ActiveModel::Type::Boolean.new.cast(attributes.delete(:remove_image))
    if attributes[:image].blank?
      attributes.delete(:image)
    elsif !attributes[:image].is_a?(ActionDispatch::Http::UploadedFile)
      raise ActionController::BadRequest, "image must be an uploaded file"
    end
    if @profile.update(attributes)
      @profile.image.purge_later if remove_image && !attributes.key?(:image)
      redirect_to my_profile_path, notice: "Profile updated.", status: :see_other
    else
      render :edit, status: :unprocessable_content
    end
  end
end
