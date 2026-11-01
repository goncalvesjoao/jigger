class CocktailPolicy
  def initialize(user, cocktail)
    @user, @cocktail = user, cocktail
  end

  def index?
    true
  end

  def show?
    @user&.admin? || @cocktail.recipes.marketplace.exists?
  end

  def create?
    @user&.admin?
  end

  alias_method :new?, :create?
  alias_method :edit?, :create?
  alias_method :update?, :create?
  alias_method :destroy?, :create?
end
