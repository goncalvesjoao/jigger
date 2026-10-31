require "test_helper"

class StepMentionTest < ActiveSupport::TestCase
  test "mentions preserve unicode prose and refer to one identity" do
    step = recipe_steps(:one)
    step.update!(body: "氷を jigger に入れる。")
    mention = step.step_mentions.create!(ingredient: ingredients(:two), start_offset: 0, end_offset: 1, quoted_text: "氷")
    utensil = step.step_mentions.create!(utensil: utensils(:jigger), start_offset: 3, end_offset: 9, quoted_text: "jigger")
    assert_not mention.update(utensil: utensils(:jigger))
    assert_not utensil.update(quoted_text: "shaker")
    assert_not mention.update(end_offset: 100)
    assert_not step.step_mentions.build.valid?
    assert_not step.step_mentions.build(start_offset: 0, end_offset: 1, quoted_text: "氷").valid?
    assert_equal "氷を jigger に入れる。", step.reload.body
    step.update!(body: "Changed words")
    assert_empty step.step_mentions.reload
  end

  test "mention targets are protected by database foreign keys" do
    recipe_steps(:one).step_mentions.create!(ingredient: ingredients(:two), start_offset: 0, end_offset: 2, quoted_text: "My")
    assert_raises(ActiveRecord::InvalidForeignKey) { ingredients(:two).delete }
  end
  test "a stale step object cannot attach a mention to changed words" do
    stale_step = RecipeStep.find(recipe_steps(:one).id)
    recipe_steps(:one).update!(body: "NewText")
    mention = stale_step.step_mentions.build(ingredient: ingredients(:one), start_offset: 0, end_offset: 2, quoted_text: "My")
    assert_not mention.save
    assert_includes mention.errors[:quoted_text], "no longer matches the saved step text"
    assert_empty StepMention.where(recipe_step_id: stale_step.id)
  end
end
