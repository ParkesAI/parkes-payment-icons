# frozen_string_literal: true

require "fileutils"
require "json"
require "rbconfig"
require "rubygems/package"
require "tmpdir"

root = File.expand_path("..", __dir__)
version = ENV.fetch("RAILS_VERSION", "~> 8.1.0")
pipeline = ENV.fetch("ASSET_PIPELINE", "propshaft")
abort "Use propshaft or sprockets" unless %w[propshaft sprockets].include?(pipeline)
spec = Gem::Specification.load(File.join(root, "parkes-payment-icons.gemspec"))
package = File.join(root, "pkg", "#{spec.full_name}.gem")

def run!(*command, **options)
  system(*command, **options, exception: true)
end

Dir.mktmpdir("payment-icons-compatibility-") do |app|
  gem_home = File.join(app, "gems")
  run!(RbConfig.ruby, "-S", "gem", "install", package, "--local", "--ignore-dependencies", "--no-document", "--install-dir", gem_home)
  File.write(File.join(app, "Gemfile"), <<~GEMFILE)
    source "https://rubygems.org"
    gem "railties", #{version.inspect}
    gem "actionpack", #{version.inspect}
    gem #{(pipeline == "propshaft" ? "propshaft" : "sprockets-rails").inspect}, #{(pipeline == "propshaft" ? "~> 1.0" : "~> 3.5").inspect}
    gem "parkes-payment-icons", #{spec.version.to_s.inspect}
    gem "rake", "~> 13.0"
    gem "logger"
  GEMFILE
  FileUtils.mkdir_p(File.join(app, "app/assets/config"))
  manifest = "//= link_tree ../images\n"
  manifest += "//= link parkes_payment_icons.js\n" if pipeline == "sprockets"
  File.write(File.join(app, "app/assets/config/manifest.js"), manifest)
  FileUtils.mkdir_p(File.join(app, "app/assets/images"))
  File.write(File.join(app, "Rakefile"), <<~RAKEFILE)
    require_relative "application"
    Rails.application.load_tasks
  RAKEFILE
  File.write(File.join(app, "application.rb"), <<~RUBY)
    require "bundler/setup"
    require "logger"
    require "rails"
    require "action_controller/railtie"
    Bundler.require
    class AssetTestApp < Rails::Application
      config.root = __dir__
      config.eager_load = true
      config.secret_key_base = "a" * 64
      config.hosts.clear
      config.public_file_server.enabled = true
      config.logger = Logger.new(File::NULL)
    end
    Rails.application.initialize!
  RUBY
  env = {
    "GEM_HOME" => gem_home,
    "GEM_PATH" => ([gem_home] + Gem.path).join(File::PATH_SEPARATOR),
    "BUNDLE_GEMFILE" => File.join(app, "Gemfile"),
    "BUNDLE_APP_CONFIG" => File.join(app, ".bundle"),
    "RAILS_ENV" => "production"
  }
  run!(env, RbConfig.ruby, "-S", "bundle", "install", "--quiet", chdir: app)
  run!(env, RbConfig.ruby, "-S", "bundle", "exec", "rake", "assets:precompile", chdir: app)
  run!(env.merge("ICON_PACKAGE_ROOT" => root), RbConfig.ruby, "-S", "bundle", "exec", "ruby", File.join(__dir__, "verify_assets.rb"), chdir: app)
end
