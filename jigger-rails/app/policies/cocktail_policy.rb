class CocktailPolicy
  def initialize(user, cocktail)
    @user = user
    @cocktail = cocktail
  end

  def index?
    true
  end

  def show?
    (@user.present? && (@user.admin? || @cocktail.user_id == @user.id)) || @cocktail.marketplace?
  end

  def create?
    @user.present?
  end

  alias_method :new?, :create?

  def update?
    @user.present? && (@user.admin? || (@cocktail.user_id == @user.id && !@cocktail.official?))
  end

  alias_method :edit?, :update?
  alias_method :destroy?, :update?
end
