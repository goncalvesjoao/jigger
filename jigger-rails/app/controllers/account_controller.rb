class AccountController < ApplicationController
  before_action :prevent_account_caching, only: %i[show destroy]

  def show
    @account = Current.user
  end

  def destroy
    @account = Current.user
    unless @account.authenticate(params[:password].to_s)
      @account.errors.add(:password, "is incorrect")
      return render :show, status: :unprocessable_content
    end

    @account.destroy!
    cookies.delete(:session_id)
    Current.reset
    reset_session
    redirect_to root_path, notice: "Your account and its content have been deleted.", status: :see_other
  rescue ActiveRecord::RecordNotDestroyed
    @account.errors.add(:base, "Your account could not be deleted. Please try again.")
    render :show, status: :unprocessable_content
  end

  def recipes
    owned_recipes = Current.user.recipes
    @recipe_counts = owned_recipes.group(:publication_state).count
    @publication_state = params[:state].presence_in(%w[draft published])
    @recipes = owned_recipes.search(params[:q])
    @recipes = @recipes.where(publication_state: @publication_state) if @publication_state
    @recipes = @recipes.with_attached_image.includes(:translations, :recipe_steps).order(updated_at: :desc, id: :desc)
  end

  private
    def prevent_account_caching
      response.headers["Cache-Control"] = "private, no-store"
    end
end
