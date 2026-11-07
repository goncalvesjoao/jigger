module ProfileImagesSeeder
  IMAGES = {
    "shakestir@shakestir.example" => "shakestir.webp",
    "leo@shakestir.example" => "leo.webp",
    "alex@shakestir.example" => "alex.webp"
  }.freeze

  def self.seed!
    IMAGES.each do |email, filename|
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
