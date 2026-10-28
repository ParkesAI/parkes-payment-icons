# frozen_string_literal: true

require File.join(Dir.pwd, "application")
require "digest"
require "json"
require "rack/mock"

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
  url = ActionController::Base.helpers.asset_path(logical)
  raise "Undigested asset: #{logical}" if url == "/assets/#{logical}"
  response = Rack::MockRequest.new(Rails.application).get(url)
  raise "Asset not served: #{logical} (#{response.status})" unless response.status == 200
  raise "Wrong served content: #{logical}" unless Digest::SHA256.hexdigest(response.body) == digest
  raise "Wrong content type: #{logical}" unless response.content_type.include?("image/svg+xml")
end
puts "PASS Ruby #{RUBY_VERSION}, Rails #{Rails.version}, #{ENV.fetch('ASSET_PIPELINE', 'propshaft')}: installed gem, automatic require, all SVG URLs, production digests and HTTP bytes"
