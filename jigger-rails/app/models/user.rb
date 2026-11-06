class User < ApplicationRecord
  validates :email_address, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }

  validates :profile_visibility, inclusion: { in: %w[private public] }
  validates :display_name, length: { maximum: 80 }
  validates :bio, length: { maximum: 280 }

  def public_profile?
    profile_visibility == "public"
  end

  def profile_name
    display_name.presence || "Jigger member"
  end

  def self.jigger_account
    find_by!(system_key: "jigger")
  end

  def jigger_account?
    system_key == "jigger"
  end

  before_validation :assign_handle, on: :create
  normalizes :handle, with: ->(value) { value.strip.downcase }
  validate { errors.add(:handle, "is reserved") if handle == "jigger" && !jigger_account? }
  validates :handle, presence: true, uniqueness: true, format: { with: /\A[a-z0-9][a-z0-9_-]{2,39}\z/ }

  def favorites_collection
    collections.find_by!(system_key: "favorites")
  end

  has_secure_password
  has_many :recipes, dependent: :restrict_with_error
  has_many :collections, dependent: :destroy
  after_create :create_favorites_collection

  has_many :sessions, dependent: :destroy

  normalizes :email_address, with: ->(e) { e.strip.downcase }
  private
    def assign_handle
      return if handle.present?

      base = email_address.to_s.split("@").first.to_s.downcase.gsub(/[^a-z0-9_-]+/, "-").sub(/\A[-_]+/, "")[0, 30]
      base = "member" if base.length < 3 || base == "jigger"
      candidate = base
      candidate = "#{base}-#{SecureRandom.hex(4)}" while User.exists?(handle: candidate)
      self.handle = candidate
    end

    def create_favorites_collection
      collections.create!(name: "Favorites", system_key: "favorites")
    end
end
