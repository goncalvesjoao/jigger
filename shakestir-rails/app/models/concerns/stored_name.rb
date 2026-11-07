module StoredName
  extend ActiveSupport::Concern

  included do
    before_validation { self.normalized_name = name.present? ? LookupName.normalize(name) : nil }
  end
end
