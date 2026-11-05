class User < ApplicationRecord
  validates :email_address, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }

  has_secure_password
  has_many :recipes, dependent: :restrict_with_error
  has_many :collections, dependent: :destroy
  after_create :create_favorites_collection

  has_many :sessions, dependent: :destroy

  normalizes :email_address, with: ->(e) { e.strip.downcase }
  private
    def create_favorites_collection
      collections.create!(name: "Favorites")
    end
end
