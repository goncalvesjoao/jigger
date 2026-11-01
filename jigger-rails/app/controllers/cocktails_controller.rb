class CocktailsController < ApplicationController
  allow_unauthenticated_access only: %i[ index show legacy ]
  before_action :set_cocktail, only: %i[ show edit update destroy ]

  before_action :authorize_cocktail, except: :legacy
  after_action :verify_authorized, except: :legacy
  around_action :with_recipe_language, only: %i[ create edit update ]

  def legacy
    cocktail = Cocktail.find_by!(legacy_user_cocktail_id: params[:id])
    authorize cocktail, :show?
    redirect_to cocktail, status: :moved_permanently
  end

  # GET /cocktails or /cocktails.json
  def index
    @cocktails = Cocktail.marketplace.search(params[:q]).with_attached_image.includes(:translations, :recipe_steps)
  end

  # GET /cocktails/1 or /cocktails/1.json
  def show
    ActiveRecord::Associations::Preloader.new(records: [ @cocktail ], associations: {
      cocktail_ingredients: { ingredient: [ :translations, { image_attachment: :blob } ] },
      cocktail_utensils: { utensil: [ :translations, { image_attachment: :blob } ] }
    }).call
  end

  # GET /cocktails/new
  def new
    @cocktail = Cocktail.new(language: I18n.locale.to_s)
  end

  # GET /cocktails/1/edit
  def edit
  end

  # POST /cocktails or /cocktails.json
  def create
    @cocktail = Cocktail.new(cocktail_params)
    @cocktail.user = Current.user

    respond_to do |format|
      if @cocktail.save
        format.html { redirect_to @cocktail, notice: "Cocktail was successfully created." }
        format.json { render :show, status: :created, location: @cocktail }
      else
        format.html { render :new, status: :unprocessable_content }
        format.json { render json: @cocktail.errors, status: :unprocessable_content }
      end
    end
  end

  # PATCH/PUT /cocktails/1 or /cocktails/1.json
  def update
    respond_to do |format|
      if @cocktail.update(cocktail_params)
        format.html { redirect_to @cocktail, notice: "Cocktail was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @cocktail }
      else
        format.html { render :edit, status: :unprocessable_content }
        format.json { render json: @cocktail.errors, status: :unprocessable_content }
      end
    end
  end

  # DELETE /cocktails/1 or /cocktails/1.json
  def destroy
    @cocktail.destroy!

    respond_to do |format|
      format.html { redirect_to cocktails_path, notice: "Cocktail was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    def with_recipe_language(&block)
      language = params.dig(:cocktail, :language).presence || @cocktail&.language
      locale = language.present? && language != "und" ? language : I18n.default_locale
      Globalize.with_locale(locale, &block)
    end

    # Use callbacks to share common setup or constraints between actions.
    def set_cocktail
      @cocktail = Cocktail.find(params.expect(:id))
    end

    def authorize_cocktail
      authorize @cocktail || Cocktail
    end

    # Only allow a list of trusted parameters through.
    def cocktail_params
      fields = [ :name, :description, :language, :steps, :preparation_time_seconds, :servings, :preparation_method, :source_reference, :source_url, :source_published_on, :source_date_note, :visibility, :publication_state, :image ]
      fields += [ :official ] if Current.user&.admin?
      fields += [ :parent_cocktail_id ]
      permitted = params.expect(cocktail: fields)
      if permitted[:parent_cocktail_id].present?
        Cocktail.readable_by(Current.user).find(permitted[:parent_cocktail_id])
      end
      if permitted[:image].blank?
        permitted.delete(:image)
      elsif !permitted[:image].is_a?(ActionDispatch::Http::UploadedFile)
        raise ActionController::BadRequest, "image must be an uploaded file"
      end
      permitted
    end
end
