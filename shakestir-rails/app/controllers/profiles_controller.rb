class ProfilesController < ApplicationController
  include CollectionPreviews

  before_action :prevent_profile_caching, only: %i[show update]

  allow_unauthenticated_access only: :show
  before_action -> { require_authentication }, only: :show, if: -> { params[:id].blank? }

  def show
    resume_session
    @profile = params[:id].present? ? User.find(params[:id]) : Current.user
    load_profile_content
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
      if request.format.json?
        return render json: { errors: { image: [ "must be an uploaded file" ] } }, status: :bad_request
      end
      raise ActionController::BadRequest, "image must be an uploaded file"
    end
    if @profile.update(attributes)
      @profile.image.purge_later if remove_image && !attributes.key?(:image)
      respond_to do |format|
        format.html { redirect_to my_profile_path, notice: "Profile updated.", status: :see_other }
        format.json do
          load_profile_content
          render :show
        end
      end
    else
      respond_to do |format|
        format.html { render :edit, status: :unprocessable_content }
        format.json { render json: { errors: @profile.errors.to_hash }, status: :unprocessable_content }
      end
    end
  end

  private
    def load_profile_content
      @owned = @profile == Current.user
      @collections = @profile.collections.where(visibility: "public").order(created_at: :desc)
      @recipes = @profile.recipes.merge(Recipe.marketplace).with_attached_image
        .includes(:recipe_steps, :techniques, :user, cocktail: { image_attachment: :blob })
        .reorder(updated_at: :desc, id: :desc)
      load_collection_previews(@collections, viewer: nil)
    end

    def prevent_profile_caching
      response.headers["Cache-Control"] = "private, no-store" if request.format.json?
    end
end
