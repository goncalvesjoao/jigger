class CocktailsController < ApplicationController
  allow_unauthenticated_access only: %i[ index show ]
  before_action :set_cocktail, only: %i[ show edit update destroy ]

  before_action :authorize_cocktail
  after_action :verify_authorized

  # GET /cocktails or /cocktails.json
  def index
    @cocktails = Cocktail.all
  end

  # GET /cocktails/1 or /cocktails/1.json
  def show
  end

  # GET /cocktails/new
  def new
    @cocktail = Cocktail.new
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
    # Use callbacks to share common setup or constraints between actions.
    def set_cocktail
      @cocktail = Cocktail.find(params.expect(:id))
    end

    def authorize_cocktail
      authorize @cocktail || Cocktail
    end

    # Only allow a list of trusted parameters through.
    def cocktail_params
      params.expect(cocktail: [ :name, :steps, :preparation_time_seconds ])
    end
end
