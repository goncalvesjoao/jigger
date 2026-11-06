require "digest"

module ApplicationHelper
  def gravatar_url(user)
    hash = Digest::SHA256.hexdigest(user.email_address.strip.downcase)
    "https://gravatar.com/avatar/#{hash}?s=80&d=mp"
  end

  def profile_avatar(user, size: 112, css_class: nil)
    own_profile = Current.user == user
    if user.image.attached?
      image_tag profile_image_path(user, size: :card), alt: "", width: size, height: size, class: css_class
    elsif own_profile
      image_tag gravatar_url(user), alt: "", width: size, height: size, class: css_class
    else
      initials = user.display_name.to_s.split.first(2).map { |part| part.first }.join.upcase.presence || "J."
      tag.span(initials, aria: { hidden: true }, class: css_class)
    end
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
