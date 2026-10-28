# frozen_string_literal: true

require File.join(Dir.pwd, "application")
require "digest"
require "json"
require "rack/mock"
require "nokogiri"

view = ActionController::Base.new.view_context

spec = Gem.loaded_specs.fetch("parkes-payment-icons")
raise "Loaded source instead of installed gem" if spec.full_gem_path.start_with?(ENV.fetch("ICON_PACKAGE_ROOT"))
source = JSON.parse(File.read(File.join(ENV.fetch("ICON_PACKAGE_ROOT"), "upstream.json")))
installed = JSON.parse(File.read(File.join(spec.full_gem_path, "upstream.json")))
raise "Missing or changed packaged provenance" unless installed == source
%w[LICENSE NOTICE].each do |name|
  raise "Missing #{name} in gem" unless File.size?(File.join(spec.full_gem_path, name))
end
source.fetch("sha256").each do |name, digest|
  path = name.end_with?(".svg") ? "app/assets/images/payment_icons/#{name}" : "vendor/upstream/#{name}"
  raise "Packaged bytes differ: #{name}" unless Digest::SHA256.file(File.join(spec.full_gem_path, path)).hexdigest == digest
  next unless name.end_with?(".svg")

  logical = "payment_icons/#{name}"
  variant, filename = name.split("/")
  icon = File.basename(filename, ".svg")
  url = view.payment_icon_path(icon, variant: variant)
  raise "Helper resolved the wrong asset: #{logical}" unless url == view.image_path(logical)
  tag = Nokogiri::HTML.fragment(view.payment_icon_tag(icon, variant: variant)).at_css("img")
  raise "Tag helper resolved the wrong asset: #{logical}" unless tag && tag["src"] == url
  raise "Undigested asset: #{logical}" if url == "/assets/#{logical}"
  response = Rack::MockRequest.new(Rails.application).get(url)
  raise "Asset not served: #{logical} (#{response.status})" unless response.status == 200
  raise "Wrong served content: #{logical}" unless Digest::SHA256.hexdigest(response.body) == digest
  raise "Wrong content type: #{logical}" unless response.content_type.include?("image/svg+xml")
end

default = Nokogiri::HTML.fragment(view.payment_icon_tag(:visa)).at_css("img")
raise "Incorrect default variant" unless default["src"] == view.image_path("payment_icons/logo/visa.svg")
raise "Missing default alt text" unless default["alt"] == "Visa"

html = view.payment_icon_tag(:mastercard, variant: :flat_rounded, alt: '<Pay "now">',
  class: "card-logo", size: "40x25", style: "opacity: 0.8", loading: "lazy", data: { brand: "mastercard" })
tag = Nokogiri::HTML.fragment(html).at_css("img")
expected = { "alt" => '<Pay "now">', "class" => "card-logo", "width" => "40", "height" => "25",
  "style" => "opacity: 0.8", "loading" => "lazy", "data-brand" => "mastercard" }
raise "HTML options were not preserved" unless expected.all? { |key, value| tag[key] == value }
raise "HTML options were not escaped" if html.include?('<Pay "now">')
raise "Symbol variant not normalized" unless tag["src"] == view.image_path("payment_icons/flat-rounded/mastercard.svg")
decorative = Nokogiri::HTML.fragment(view.payment_icon_tag(:visa, alt: "")).at_css("img")
raise "Decorative alt text was overwritten" unless decorative["alt"] == ""
raise "Path host option was ignored" unless view.payment_icon_path(:visa, host: "https://assets.example.test").start_with?("https://assets.example.test/")

[["missing", :logo], ["../visa", :logo], [:visa, "../logo"], [:visa, :missing], [nil, :logo], [:visa, nil]].each do |name, variant|
  begin
    view.payment_icon_tag(name, variant: variant)
  rescue ArgumentError => error
    raise unless error.message.start_with?("Unknown payment icon", "Payment icon name and variant")
    # Both helpers must reject invalid inputs before asking the asset pipeline.
  else
    raise "Tag helper accepted invalid name/variant: #{[name, variant].inspect}"
  end
  begin
    view.payment_icon_path(name, variant: variant)
  rescue ArgumentError => error
    raise unless error.message.start_with?("Unknown payment icon", "Payment icon name and variant")
    next
  end
  raise "Path helper accepted invalid name/variant: #{[name, variant].inspect}"
end
puts "PASS Ruby #{RUBY_VERSION}, Rails #{Rails.version}, #{ENV.fetch('ASSET_PIPELINE', 'propshaft')}: installed gem, automatic helpers, all SVG URLs, production digests and HTTP bytes"
