require "administrate/base_dashboard"

class UserDashboard < Administrate::BaseDashboard
  ATTRIBUTE_TYPES = { email_address: Field::Email }.freeze
  COLLECTION_ATTRIBUTES = %i[email_address].freeze
  SHOW_PAGE_ATTRIBUTES = COLLECTION_ATTRIBUTES
  FORM_ATTRIBUTES = [].freeze

  def display_resource(resource)
    resource.email_address
  end
end
