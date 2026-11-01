require "digest"

module ApplicationHelper
  def gravatar_url(user)
    hash = Digest::SHA256.hexdigest(user.email_address.strip.downcase)
    "https://gravatar.com/avatar/#{hash}?s=80&d=mp"
  end

  FLASH_TYPE_CSS_CLASS = { info: "info", alert: "danger", notice: "success" }

  def flash_messages
    safe_join([ :alert, :notice ].filter_map do |type|
      flash_message(flash[type], type)
    end)
  end

  def flash_message(message, type = :info)
    return nil if message.blank?

    tag.div(role: "status", class: FLASH_TYPE_CSS_CLASS[type]) do
      tag.span(aria_hidden: "true", class: "icon-invalid") +
      tag.span(message) +
      tag.button(aria_label: "Close", class: "icon-close", onclick: "this.parentElement.remove()")
    end
  end
end
