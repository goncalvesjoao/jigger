module LookupName
  extend ActiveSupport::Concern

  included do
    before_validation { self.normalized_name = LookupName.normalize(name) }
    validates :name, :language, :normalized_name, presence: true
  end

  def self.normalize(text)
    text.to_s.unicode_normalize(:nfkc).downcase.strip.gsub(/\s+/, " ")
  end
end
