require "test_helper"

class TechniqueTest < ActiveSupport::TestCase
  test "English learning content and unique stable slugs are required without a photo" do
    technique = Technique.new(slug: "new-technique")
    assert_not technique.valid?
    assert_includes technique.errors[:instructions], "needs an English translation"
    technique.name = "New technique"
    technique.description = "What it does."
    technique.instructions = "How to do it."
    assert technique.valid?, technique.errors.full_messages.join(", ")
    technique.slug = "shake"
    assert_not technique.valid?
    technique.slug = "Not a slug"
    assert_not technique.valid?
  end

  test "translations fall back to English and English content cannot be removed" do
    technique = techniques(:shake)
    Globalize.with_locale(:ja) do
      assert_equal "Shake", technique.name
      technique.update!(name: "シェイク")
      assert_equal "シェイク", technique.name
      assert_equal "Seal the shaker and shake with ice, then strain.", technique.instructions
    end
    assert_not technique.translation_for(:en).destroy
    assert_not technique.update(description: "")
    assert_equal "shake", technique.to_param
  end

  test "recipe links are unique and protect catalog entries until unassigned" do
    recipe = recipes(:one)
    technique = techniques(:stir)
    recipe.recipe_techniques.create!(technique: technique)
    assert_not recipe.recipe_techniques.build(technique: technique).valid?
    assert_not technique.destroy
    assert Technique.exists?(technique.id)
    assert_difference("RecipeTechnique.count", -1) { recipe.destroy! }
    assert technique.reload.destroy
  end
end
