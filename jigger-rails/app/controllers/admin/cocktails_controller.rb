class Admin::CocktailsController < ApplicationController
  before_action :set_cocktail, only: %i[edit update destroy]
  before_action { authorize @cocktail || Cocktail }
  after_action :verify_authorized

  def new
    @cocktail = Cocktail.new
  end

  def edit
  end

  def create
    @cocktail = Cocktail.new(cocktail_params)
    if @cocktail.save
      redirect_to @cocktail, notice: "Cocktail created."
    else
      render :new, status: :unprocessable_content
    end
  end

  def update
    if @cocktail.update(cocktail_params)
      redirect_to @cocktail, notice: "Cocktail updated."
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @cocktail.destroy!
    redirect_to cocktails_path, status: :see_other
  end

  private
    def set_cocktail
      @cocktail = Cocktail.find(params.expect(:id))
    end

    def cocktail_params
      params.expect(cocktail: [ :name, :description, :history, :source_reference, :source_url, :source_published_on, :source_date_note ])
    end
end
