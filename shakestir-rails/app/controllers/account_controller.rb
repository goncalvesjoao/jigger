class AccountController < ApplicationController
  before_action :prevent_account_caching, only: %i[show recipes destroy]

  def show
    @account = Current.user
  end

  def destroy
    @account = Current.user
    unless @account.authenticate(params[:password].to_s)
      @account.errors.add(:password, "is incorrect")
      return render_deletion_errors
    end

    @account.destroy!
    cookies.delete(:session_id)
    Current.reset
    reset_session
    respond_to do |format|
      format.html { redirect_to root_path, notice: "Your account and its content have been deleted.", status: :see_other }
      format.json { head :no_content }
    end
  rescue ActiveRecord::RecordNotDestroyed
    @account.errors.add(:base, "Your account could not be deleted. Please try again.")
    render_deletion_errors
  end

  def recipes
    owned_recipes = Current.user.recipes
    @recipe_counts = owned_recipes.group(:publication_state).count
    @publication_state = params[:state].presence_in(%w[draft published])
    @recipes = owned_recipes.search(params[:q])
    @recipes = @recipes.where(publication_state: @publication_state) if @publication_state
    @recipes = @recipes.with_attached_image.includes(:recipe_steps, :techniques, :user, cocktail: { image_attachment: :blob })
      .order(updated_at: :desc, id: :desc)
    @pagination = @recipes = @recipes.page(params[:page]).per(24) if request.format.json?
  end

  private
    def render_deletion_errors
      respond_to do |format|
        format.html { render :show, status: :unprocessable_content }
        format.json { render json: { errors: @account.errors.to_hash }, status: :unprocessable_content }
      end
    end

    def prevent_account_caching
      response.headers["Cache-Control"] = "private, no-store"
    end
end
