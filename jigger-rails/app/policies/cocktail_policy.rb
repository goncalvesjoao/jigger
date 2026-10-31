class CocktailPolicy
  def initialize(user, cocktail)
    @user = user
    @cocktail = cocktail
  end

  def index?
    true
  end

  alias_method :show?, :index?

  def create?
    @user.present?
  end

  alias_method :new?, :create?

  def update?
    @user.present? && @cocktail.user_id == @user.id
  end

  alias_method :edit?, :update?
  alias_method :destroy?, :update?
end
