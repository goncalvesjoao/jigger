require "json"

module ProfileImagesSeeder
  def self.seed!
    images = JSON.parse(Rails.root.parent.join("db/seeds/avatars/profiles.json").read)
    images.each do |email, filename|
      user = User.find_by(email_address: email)
      next unless user && !user.image.attached?

      path = Rails.root.parent.join("db/seeds/avatars", filename)
      File.open(path, "rb") do |file|
        user.image.attach(io: file, filename: filename, content_type: "image/webp")
      end
      user.save!
    end
  end
end
