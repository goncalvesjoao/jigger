class RecipePolicy
  def initialize(user, recipe)
    @user = user
    @recipe = recipe
  end

  def index?
    true
  end

  def show?
    (@user.present? && @recipe.user_id == @user.id) || @recipe.marketplace?
  end

  def create?
    @user.present?
  end

  alias_method :new?, :create?

  def update?
    @user.present? && @recipe.user_id == @user.id
  end

  alias_method :edit?, :update?
  alias_method :destroy?, :update?
end
