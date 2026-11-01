require "administrate/field/string"

class TranslatedField < Administrate::Field::String
  def self.sortable?
    false
  end

  def read_value(data)
    page == :form ? resource.translation_for(Globalize.locale, false)&.[](attribute) : super
  end
end
