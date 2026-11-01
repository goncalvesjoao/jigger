class AccountController < ApplicationController
  def recipes
    @recipes = Current.user.recipes.with_attached_image.includes(:translations, :recipe_steps)
  end

  def lists
  end

  def profile
  end
end
