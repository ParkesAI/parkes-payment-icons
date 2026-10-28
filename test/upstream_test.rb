# frozen_string_literal: true

require "minitest/autorun"
require_relative "../tasks/upstream"

class UpstreamTest < Minitest::Test
  def setup
    @directory = Dir.mktmpdir("payment-icons-test-")
    @source = File.join(@directory, "source")
    @target = File.join(@directory, "target")
    FileUtils.mkdir_p([@source, @target])
    license = File.binread(File.expand_path("../LICENSE", __dir__))
    [@source, @target].each { |root| File.binwrite(File.join(root, "LICENSE"), license) }
    Upstream::STYLES.each do |style|
      FileUtils.mkdir_p(File.join(@source, style))
      File.binwrite(File.join(@source, style, "card.svg"), "<svg xmlns=\"http://www.w3.org/2000/svg\"><path d=\"M0 0\"/></svg>\r\n")
    end
    Upstream.git("init", "--quiet", @source)
  end

  def teardown
    FileUtils.remove_entry(@directory)
  end

  def commit
    Upstream.git("-C", @source, "add", ".")
    Upstream.git("-C", @source, "-c", "user.name=Test", "-c", "user.email=test@example.invalid", "commit", "--quiet", "-m", "Fixture revision")
    Upstream.git("-C", @source, "rev-parse", "HEAD").strip
  end

  def update(revision)
    Upstream.update(@target, revision, repository: @source)
  end

  def test_import_preserves_bytes_and_notices_and_removes_retired_files
    File.binwrite(File.join(@source, "NOTICE"), "Upstream attribution\r\n")
    first = commit
    update(first)
    assert_equal "Upstream attribution\r\n", File.binread(File.join(@target, "vendor/upstream/NOTICE"))
    asset = File.join(Upstream::ASSETS, "logo/card.svg")
    assert_equal File.binread(File.join(@source, "logo/card.svg")), File.binread(File.join(@target, asset))
    capture_io { Upstream.verify(@target, fetch: true, repository: @source) }

    FileUtils.mv(File.join(@source, "logo/card.svg"), File.join(@source, "logo/new-card.svg"))
    FileUtils.rm(File.join(@source, "NOTICE"))
    update(commit)
    refute_path_exists File.join(@target, asset)
    refute_path_exists File.join(@target, "vendor/upstream/NOTICE")
    capture_io { Upstream.verify(@target, fetch: true, repository: @source) }
  end

  def test_verification_detects_tampered_assets_and_unrecorded_extras
    update(commit)
    file = File.join(@target, Upstream::ASSETS, "logo/card.svg")
    original = File.binread(file)
    File.binwrite(file, original + "\n")
    assert_match(/differ/, assert_raises(RuntimeError) { Upstream.verify(@target) }.message)
    File.binwrite(file, original)
    File.binwrite(File.join(@target, Upstream::ASSETS, "logo/extra.svg"), original)
    assert_match(/differ/, assert_raises(RuntimeError) { Upstream.verify(@target) }.message)
  end

  def test_changed_license_or_active_svg_is_rejected_before_replacing_existing_assets
    update(commit)
    manifest = File.binread(File.join(@target, "upstream.json"))
    File.write(File.join(@source, "LICENSE"), "Different license")
    assert_match(/license changed/, assert_raises(RuntimeError) { update(commit) }.message)
    assert_equal manifest, File.binread(File.join(@target, "upstream.json"))
    FileUtils.cp(File.join(@target, "LICENSE"), File.join(@source, "LICENSE"))
    File.write(File.join(@source, "logo/card.svg"), '<svg><script>alert(1)</script></svg>')
    assert_match(/Active SVG/, assert_raises(RuntimeError) { update(commit) }.message)
    capture_io { Upstream.verify(@target) }
  end

  def test_rejects_unpinned_revisions
    assert_raises(ArgumentError) { update("main") }
  end

  def test_rejects_active_or_external_svg_content
    [
      '<!DOCTYPE svg [<!ENTITY external SYSTEM "file:///etc/passwd">]><svg/>',
      '<svg onload="alert(1)"/>',
      '<svg><image href="https://example.com/image.svg"/></svg>',
      '<svg><path fill="url(https://example.com/a)"/></svg>',
      '<svg><foreignObject/></svg>'
    ].each do |svg|
      assert_raises(RuntimeError) { Upstream.validate_svg!(svg) }
    end
  end
end
