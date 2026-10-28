# frozen_string_literal: true

require "digest"
require "fileutils"
require "json"
require "open3"
require "rexml/document"
require "tmpdir"

module Upstream
  REPOSITORY = "https://github.com/aaronfagan/svg-credit-card-payment-icons.git"
  STYLES = %w[flat flat-rounded logo logo-border mono mono-outline].freeze
  ASSETS = "app/assets/images/payment_icons"

  def self.git(*args)
    output, error, status = Open3.capture3("git", *args)
    raise "git failed: #{error}" unless status.success?
    output
  end

  def self.snapshot(revision, repository: REPOSITORY)
    raise ArgumentError, "Use a full 40-character commit SHA" unless /\A[0-9a-f]{40}\z/.match?(revision)

    Dir.mktmpdir("payment-icons-upstream-") do |directory|
      git("init", "--quiet", directory)
      git("-C", directory, "fetch", "--quiet", "--depth=1", "--", repository, revision)
      git("-C", directory, "checkout", "--quiet", "--detach", "FETCH_HEAD")
      raise "Fetched revision differs" unless git("-C", directory, "rev-parse", "HEAD").strip == revision

      files = {}
      STYLES.each do |style|
        paths = Dir.glob("#{directory}/#{style}/*.svg").sort
        raise "Missing icons for #{style}" if paths.empty?
        paths.each do |path|
          raise "Refusing symlink #{path}" if File.symlink?(path)
          name = File.basename(path)
          raise "Invalid icon filename #{name}" unless /\A[a-z0-9-]+\.svg\z/.match?(name)
          bytes = File.binread(path)
          validate_svg!(bytes)
          files["#{style}/#{name}"] = bytes
        end
      end
      %w[LICENSE NOTICE].each do |name|
        path = File.join(directory, name)
        raise "Refusing symlink #{name}" if File.symlink?(path)
        files[name] = File.binread(path) if File.file?(path)
      end
      raise "Missing upstream LICENSE" unless files.key?("LICENSE")
      yield files
    end
  end

  def self.validate_svg!(bytes)
    raise "SVG declarations/entities are not allowed" if bytes.match?(/<!DOCTYPE|<!ENTITY/i)
    document = REXML::Document.new(bytes)
    raise "Expected SVG root" unless document.root&.name == "svg"
    REXML::XPath.each(document, "//*") do |element|
      raise "Active SVG content: #{element.name}" if %w[script foreignObject iframe object embed animate animateMotion animateTransform set].include?(element.name)
      validate_css!(element.text.to_s) if element.name == "style"
      element.attributes.each_attribute do |attribute|
        raise "SVG event handler" if attribute.name.downcase.start_with?("on")
        if attribute.name == "href" && !attribute.value.start_with?("#")
          raise "External SVG reference"
        end
        validate_css!(attribute.value)
      end
    end
  end

  def self.validate_css!(text)
    raise "Unsupported SVG CSS" if text.match?(/@import|expression\s*\(|\\/i)
    text.scan(/url\((.*?)\)/i).each do |(url)|
      raise "External SVG URL" unless /\A[\s'"]*#[a-zA-Z0-9_-]+[\s'"]*\z/.match?(url)
    end
  end

  def self.manifest(revision, files)
    { "repository" => REPOSITORY, "revision" => revision,
      "sha256" => files.sort.to_h.transform_values { |bytes| Digest::SHA256.hexdigest(bytes) } }
  end

  def self.update(root, revision, repository: REPOSITORY)
    snapshot(revision, repository: repository) do |files|
      unless files.fetch("LICENSE") == File.binread(File.join(root, "LICENSE"))
        raise "Upstream license changed; review it before importing"
      end
      FileUtils.rm_rf(File.join(root, ASSETS))
      FileUtils.mkdir_p(File.join(root, "vendor/upstream"))
      FileUtils.rm_f(File.join(root, "vendor/upstream/NOTICE"))
      files.each do |name, bytes|
        relative = name.include?("/") ? "#{ASSETS}/#{name}" : "vendor/upstream/#{name}"
        destination = File.join(root, relative)
        FileUtils.mkdir_p(File.dirname(destination))
        File.binwrite(destination, bytes)
      end
      File.write(File.join(root, "upstream.json"), JSON.pretty_generate(manifest(revision, files)) + "\n")
    end
  end

  def self.verify(root, fetch: false, repository: REPOSITORY)
    recorded = JSON.parse(File.read(File.join(root, "upstream.json")))
    raise "Unexpected upstream repository" unless recorded.fetch("repository") == REPOSITORY
    files = Dir.glob("#{root}/#{ASSETS}/**/*", File::FNM_DOTMATCH).select { |path| File.file?(path) }.to_h do |path|
      raise "Refusing asset symlink" if File.symlink?(path)
      bytes = File.binread(path)
      validate_svg!(bytes)
      [path.delete_prefix("#{root}/#{ASSETS}/"), bytes]
    end
    %w[LICENSE NOTICE].each do |name|
      path = File.join(root, "vendor/upstream", name)
      files[name] = File.binread(path) if File.file?(path)
    end
    raise "License differs from upstream" unless files.fetch("LICENSE") == File.binread(File.join(root, "LICENSE"))
    raise "Vendored files differ from upstream.json" unless manifest(recorded.fetch("revision"), files) == recorded
    if fetch
      snapshot(recorded.fetch("revision"), repository: repository) do |source|
        raise "Pinned upstream differs from recorded files" unless manifest(recorded.fetch("revision"), source) == recorded
      end
    end
    puts "Verified #{files.keys.count { |name| name.end_with?(".svg") }} SVGs and upstream license notices"
  end
end
