require "administrate/field/base"

class PhotoField < Administrate::Field::Base
  def self.sortable?
    false
  end
end
