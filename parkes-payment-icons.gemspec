# frozen_string_literal: true

require_relative "lib/parkes/payment_icons/version"

Gem::Specification.new do |spec|
  spec.name = "parkes-payment-icons"
  spec.version = Parkes::PaymentIcons::VERSION
  spec.authors = ["Parkes contributors"]
  spec.summary = "Payment method SVG assets for Rails"
  spec.description = "Self-hosted payment method SVGs in six styles, packaged as a Rails asset engine. Artwork by Aaron Fagan and contributors."
  spec.homepage = "https://github.com/ParkesAI/parkes-payment-icons"
  spec.license = "Apache-2.0"
  spec.required_ruby_version = ">= 3.2"
  spec.files = Dir["app/assets/images/**/*.svg", "app/assets/config/*.js", "lib/**/*.rb", "LICENSE", "NOTICE", "README.md", "CHANGELOG.md", "CONTRIBUTING.md", "docs/*.md", "upstream.json", "vendor/upstream/*"].sort
  spec.require_paths = ["lib"]
  spec.metadata = {
    "source_code_uri" => spec.homepage,
    "bug_tracker_uri" => "#{spec.homepage}/issues",
    "changelog_uri" => "#{spec.homepage}/blob/master/CHANGELOG.md",
    "rubygems_mfa_required" => "true"
  }
  spec.add_dependency "railties", ">= 7.0", "< 9"
end
