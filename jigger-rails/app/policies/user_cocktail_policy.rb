class UserCocktailPolicy
  def initialize(user, user_cocktail)
    @user = user
    @user_cocktail = user_cocktail
  end

  def index?
    true
  end

  def show?
    update? || @user_cocktail.marketplace?
  end

  def create?
    @user.present?
  end

  alias_method :new?, :create?

  def update?
    @user.present? && @user_cocktail.user_id == @user.id
  end

  alias_method :edit?, :update?
  alias_method :destroy?, :update?
end
