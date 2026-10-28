# frozen_string_literal: true

require "rubygems/package"
require "rake/testtask"
require_relative "tasks/upstream"

Rake::TestTask.new do |test|
  test.pattern = "test/**/*_test.rb"
end

desc "Build the distributable gem in pkg/ (does not publish)"
task :build do
  mkdir_p "pkg"
  spec = Gem::Specification.load("parkes-payment-icons.gemspec")
  Gem::Package.build(spec, false, true, "pkg/#{spec.full_name}.gem")
end

desc "Install the built gem and verify Rails assets (RAILS_VERSION, ASSET_PIPELINE)"
task compatibility: :build do
  Bundler.with_unbundled_env do
    ruby "test/compatibility.rb"
  end
end

task default: :test

namespace :upstream do
  desc "Import untouched SVGs and license notices from a pinned upstream commit"
  task :update, [:revision] do |_task, args|
    Upstream.update(Dir.pwd, args.fetch(:revision))
    Upstream.verify(Dir.pwd)
  end

  desc "Check local SVGs, license notices and checksums (offline)"
  task :check do
    Upstream.verify(Dir.pwd)
  end

  desc "Fetch the pinned upstream revision and verify every vendored byte"
  task :verify do
    Upstream.verify(Dir.pwd, fetch: true)
  end
end
