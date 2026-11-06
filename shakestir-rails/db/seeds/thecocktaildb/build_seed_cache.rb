require "json"
require "openssl"
require "uri"
require "net/http"

API_BASE = "https://www.thecocktaildb.com/api/json/v1/1"
ROOT = File.expand_path(".", __dir__)

COCKTAILS = [
  "Margarita", "Old Fashioned", "Mojito", "Daiquiri", "Negroni", "Manhattan",
  "Espresso Martini", "Moscow Mule", "Whiskey Sour", "Piña Colada", "Gimlet", "Sidecar"
].freeze

INGREDIENTS = [
  "Gin", "Vodka", "Rum", "Tequila", "Bourbon", "Whiskey", "Lime Juice", "Simple Syrup",
  "Triple Sec", "Bitters", "Mint", "Pineapple Juice", "Cranberry Juice", "Ginger Beer"
].freeze

Dir.mkdir(File.join(ROOT, "images", "cocktails")) unless Dir.exist?(File.join(ROOT, "images", "cocktails"))
Dir.mkdir(File.join(ROOT, "images", "ingredients")) unless Dir.exist?(File.join(ROOT, "images", "ingredients"))

def slugify(value)
  value.to_s.downcase.gsub(/[^a-z0-9]+/, "-").gsub(/^-+|-+$/, "")
end

def fetch_json(path)
  uri = URI.parse("#{API_BASE}#{path}")
  response = Net::HTTP.get_response(uri)
  return {} unless response.is_a?(Net::HTTPSuccess)

  JSON.parse(response.body)
end

def fetch_binary(url)
  return nil if url.to_s.strip.empty?

  uri = URI.parse(url)
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = uri.scheme == "https"
  response = http.get(uri.request_uri)
  response.is_a?(Net::HTTPSuccess) ? response.body : nil
end

def ingredient_image_candidates(name)
  encoded_name = URI.encode_uri_component(name)
  [
    "https://www.thecocktaildb.com/images/ingredients/#{encoded_name}.png",
    "https://www.thecocktaildb.com/images/ingredients/#{encoded_name}-small.png",
    "https://www.thecocktaildb.com/images/ingredients/#{encoded_name}-medium.png"
  ]
end

cocktails = []
COCKTAILS.each do |drink_name|
  payload = fetch_json("/search.php?s=#{URI.encode_www_form_component(drink_name)}")
  Array(payload["drinks"]).each { |drink| cocktails << drink }
end
File.write(File.join(ROOT, "cocktails.json"), JSON.pretty_generate({ "drinks" => cocktails }))

ingredients = []
recipe_ingredients = cocktails.flat_map { |drink| (1..15).map { |i| drink["strIngredient#{i}"] } }.compact.map(&:strip).reject(&:empty?)
(INGREDIENTS + recipe_ingredients).uniq { |name| name.downcase }.each do |ingredient_name|
  payload = fetch_json("/search.php?i=#{URI.encode_www_form_component(ingredient_name)}")
  ingredient = Array(payload["ingredients"]).first
  ingredients << ingredient if ingredient
end
File.write(File.join(ROOT, "ingredients.json"), JSON.pretty_generate({ "ingredients" => ingredients }))

cocktails.each do |drink|
  next unless drink["strDrinkThumb"].to_s.strip != ""

  filename = "#{slugify(drink["strDrink"])}.jpg"
  data = fetch_binary(drink["strDrinkThumb"])
  File.binwrite(File.join(ROOT, "images", "cocktails", filename), data) if data
end

(INGREDIENTS + recipe_ingredients).uniq { |name| name.downcase }.each do |name|
  ingredient = ingredients.find { |entry| entry["strIngredient"].casecmp?(name) } || {}
  image_url = ingredient["strIngredientThumb"].to_s.strip
  image_url = ingredient_image_candidates(name).find { |candidate| fetch_binary(candidate) } if image_url.empty?
  next if image_url.nil?

  filename = "#{slugify(name)}.png"
  data = fetch_binary(image_url)
  File.binwrite(File.join(ROOT, "images", "ingredients", filename), data) if data
end

puts "Cached #{cocktails.length} cocktails and #{ingredients.length} ingredients."
