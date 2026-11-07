class CocktailPolicy
  def initialize(_user, cocktail)
    @cocktail = cocktail
  end

  def index?
    true
  end

  def show?
    @cocktail.recipes.marketplace.exists?
  end
end
