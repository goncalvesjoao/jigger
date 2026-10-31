class UserCocktailsController < ApplicationController
  allow_unauthenticated_access only: %i[ index show ]
  before_action :set_user_cocktail, only: %i[ show edit update destroy ]

  before_action :authorize_user_cocktail
  after_action :verify_authorized

  # GET /user_cocktails or /user_cocktails.json
  def index
    @user_cocktails = UserCocktail.readable_by(Current.user).with_attached_image.includes(:recipe_steps)
  end

  # GET /user_cocktails/1 or /user_cocktails/1.json
  def show
    ActiveRecord::Associations::Preloader.new(records: [ @user_cocktail ], associations: {
      user_cocktail_ingredients: { ingredient: [ :translations, { image_attachment: :blob } ] },
      user_cocktail_utensils: { utensil: [ :translations, { image_attachment: :blob } ] }
    }).call
  end

  # GET /user_cocktails/new
  def new
    @user_cocktail = UserCocktail.new
  end

  # GET /user_cocktails/1/edit
  def edit
  end

  # POST /user_cocktails or /user_cocktails.json
  def create
    @user_cocktail = UserCocktail.new(user_cocktail_params)
    @user_cocktail.user = Current.user

    respond_to do |format|
      if @user_cocktail.save
        format.html { redirect_to @user_cocktail, notice: "Cocktail was successfully created." }
        format.json { render :show, status: :created, location: @user_cocktail }
      else
        format.html { render :new, status: :unprocessable_content }
        format.json { render json: @user_cocktail.errors, status: :unprocessable_content }
      end
    end
  end

  # PATCH/PUT /user_cocktails/1 or /user_cocktails/1.json
  def update
    respond_to do |format|
      if @user_cocktail.update(user_cocktail_params)
        format.html { redirect_to @user_cocktail, notice: "Cocktail was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @user_cocktail }
      else
        format.html { render :edit, status: :unprocessable_content }
        format.json { render json: @user_cocktail.errors, status: :unprocessable_content }
      end
    end
  end

  # DELETE /user_cocktails/1 or /user_cocktails/1.json
  def destroy
    @user_cocktail.destroy!

    respond_to do |format|
      format.html { redirect_to user_cocktails_path, notice: "Cocktail was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_user_cocktail
      @user_cocktail = UserCocktail.find(params.expect(:id))
    end

    def authorize_user_cocktail
      authorize @user_cocktail || UserCocktail
    end

    # Only allow a list of trusted parameters through.
    def user_cocktail_params
      permitted = params.expect(user_cocktail: [ :name, :description, :language, :steps, :preparation_time_seconds, :servings, :preparation_method, :source_reference, :image ])
      if permitted[:image].blank?
        permitted.delete(:image)
      elsif !permitted[:image].is_a?(ActionDispatch::Http::UploadedFile)
        raise ActionController::BadRequest, "image must be an uploaded file"
      end
      permitted
    end
end
