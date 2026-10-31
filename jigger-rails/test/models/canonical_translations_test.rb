require "test_helper"

class CanonicalTranslationsTest < ActiveSupport::TestCase
  def identity_types
    [ [ Ingredient, :ingredient_aliases ], [ Utensil, :utensil_aliases ], [ Cocktail, :cocktail_aliases ] ]
  end

  test "English creation and updates store content only in translations and normalize names" do
    identity_types.each do |type, association|
      assert_not type.new.valid?
      assert_no_difference([ type.name + ".count", type.translation_class.name + ".count" ]) do
        assert_raises(ActiveRecord::RecordInvalid) { type.create!(name: " ") }
        assert_raises(ActiveRecord::RecordInvalid) { Globalize.with_locale(:ja) { type.create!(name: "ジン") } }
      end
      identity = type.create!(name: "  ＧＩＮ  ", description: "English description")
      assert identity.usable?
      assert_equal "  ＧＩＮ  ", identity.reload.name
      assert_equal "gin", identity.translations.sole.normalized_name
      assert_equal :en, identity.translations.sole.locale
      assert_empty identity.public_send(association)
      %w[name description history language normalized_name].each { |field| assert_not type.column_names.include?(field) }
      identity.update!(name: "  New name  ")
      assert_equal "new name", identity.reload.translations.sole.normalized_name
      assert_equal "English description", identity.description
    end
  end

  test "localized fields fall back to English independently without affecting exact locale lookup" do
    identity_types.each do |type, _association|
      identity = type.create!(name: "Gin", description: "English description")
      Globalize.with_locale(:ja) do
        assert_equal "Gin", identity.name
        assert_equal "English description", identity.description
        assert_empty type.lookup("Gin", language: "ja")
        identity.update!(name: "  ジン  ", description: "")
        assert_equal "  ジン  ", identity.name
        assert_equal "English description", identity.description
        assert_equal [ identity.id ], type.lookup("ジン", language: "ja").ids
      end
      assert_equal "Gin", identity.name
      assert_empty type.lookup("ジン", language: "en")
      assert_equal "ジン", identity.translations.find_by!(locale: "ja").normalized_name
      Globalize.with_locale(:pt) do
        identity.update!(description: "Portuguese description")
        assert_equal "Gin", identity.name
        assert_nil identity.translations.find_by!(locale: "pt").name
        assert_empty type.lookup("Gin", language: "pt")
        assert_empty type.lookup(" ", language: "pt")
      end
    end
  end

  test "optional descriptions can be absent and empty localized names fall back" do
    identity_types.each do |type, _association|
      identity = type.create!(name: "Gin")
      assert_nil identity.description
      Globalize.with_locale(:ja) do
        identity.update!(name: "", description: "Only a description")
        assert_equal "Gin", identity.name
      end
      assert_nil identity.reload.translations.find_by!(locale: "ja").normalized_name
    end
  end

  test "saving multiple locales is atomic and failed English validation saves neither locale" do
    identity_types.each do |type, _association|
      identity = type.new(name: "First")
      Globalize.with_locale(:ja) { identity.name = "最初" }
      identity.save!
      assert_equal 2, identity.reload.translations.count
      identity.name = " "
      Globalize.with_locale(:pt) { identity.name = "Primeiro" }
      assert_not identity.save
      assert_equal "First", identity.reload.name
      assert_equal 2, identity.translations.count
      assert_not identity.translations.exists?(locale: "pt")
      broken = type.new(name: "English")
      Globalize.with_locale(:"") { broken.name = "Invalid locale" }
      assert_no_difference([ type.name + ".count", type.translation_class.name + ".count" ]) do
        assert_raises(ActiveRecord::RecordInvalid) { broken.save! }
      end
    end
  end

  test "locale uniqueness and identity references are enforced by models and database" do
    identity_types.each do |type, _association|
      identity = type.create!(name: "Gin")
      english = identity.translations.sole
      duplicate = english.dup
      assert_not duplicate.valid?
      assert_raises(ActiveRecord::RecordNotUnique) { duplicate.save!(validate: false) }
      foreign_key = type.translation_options[:foreign_key]
      orphan = english.dup
      orphan[foreign_key] = -1
      assert_raises(ActiveRecord::InvalidForeignKey) { orphan.save!(validate: false) }
      assert_not english.update(locale: "ja")
      assert_not english.reload.destroy
      assert_equal "Gin", identity.reload.name
      assert_not english.update(name: " ")
      assert identity.reload.destroy
      assert_not type.translation_class.exists?(english.id)
    end
  end

  test "missing English content excludes each required identity from publication and discovery" do
    variation = user_cocktails(:one)
    [ variation.cocktail, ingredients(:one), utensils(:jigger) ].each do |identity|
      Globalize.with_locale(:ja) { identity.update!(name: "別の名前") }
      english = identity.translation_for(:en, false)
      attributes = english.attributes
      identity.translations.where(locale: "en").delete_all
      variation.reload
      assert_nil identity.reload.name
      assert_not identity.usable?
      Globalize.with_locale(:ja) { assert_not identity.usable? }
      assert_not variation.valid?
      assert_not variation.marketplace?
      assert_not_includes UserCocktail.marketplace, variation
      assert_not_includes UserCocktail.makeable_with(ingredient_ids: Ingredient.ids, utensil_ids: Utensil.ids), variation
      assert_empty identity.class.lookup(attributes["name"], language: "en")
      assert variation.update(publication_state: "draft")
      identity.class.translation_class.insert_all!([ attributes ])
      variation.reload.update!(publication_state: "published")
    end
  end

  test "translated canonical names never overwrite user recipe or ingredient submissions" do
    variation = user_cocktails(:one)
    line = variation.user_cocktail_ingredients.sole
    before = [ variation.name, variation.language, line.submitted_text, line.language ]
    Globalize.with_locale(:ja) do
      variation.cocktail.update!(name: "マルガリータ", description: "説明")
      line.ingredient.update!(name: "ジン")
    end
    assert_equal before, [ variation.reload.name, variation.language, line.reload.submitted_text, line.language ]
    assert_equal "Margarita", variation.cocktail.name
    assert_equal [ variation.cocktail_id ], Cocktail.lookup("マルガリータ", language: "ja").ids
  end
  test "only cocktails have translated history with English fallback" do
    [ Ingredient, Utensil ].each do |type|
      assert_not type.new.respond_to?(:history)
      assert_not type.translation_class.column_names.include?("history")
    end
    cocktail = Cocktail.create!(name: "Margarita")
    assert_nil cocktail.history
    cocktail.update!(history: "English history")
    Globalize.with_locale(:ja) do
      assert_equal "English history", cocktail.history
      cocktail.update!(history: "日本語の歴史")
      assert_equal "日本語の歴史", cocktail.history
    end
    assert_equal "English history", cocktail.reload.history
  end
end
