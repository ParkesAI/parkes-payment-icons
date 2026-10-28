# Maintenance and release

## Updating upstream

1. Choose and review a full commit SHA from the upstream repository, including its
   license, notices, SVG changes, and any brand restrictions. Do not import a moving branch.
2. Run `bundle exec rake 'upstream:update[SHA]'`. Confirm the generated inventory
   and original SVG bytes. A license change deliberately stops the import; review
   its compatibility before changing the importer or licensing arrangement.
3. Run `bundle exec rake upstream:verify test compatibility`. Review removals and
   renames as API changes: consumers depend on stable asset paths. Run the other
   asset pipeline locally and require the complete CI matrix to pass.
4. Update README collection details, the recorded revision description, and
   CHANGELOG. Increment the gem version appropriately. Commit the imported files
   and generated manifest together. Preserve the `.gitattributes` byte policy.

## Preparing a release

1. Confirm release authority for the Rails wrapper and review attribution and
   trademark wording. Keep original upstream license notices in the package.
2. Update the version and changelog, build with `bundle exec rake build`, and review
   `gem specification pkg/parkes-payment-icons-VERSION.gem files`. The archive must
   contain the Ruby entry points, all assets, LICENSE, NOTICE, provenance manifest,
   and upstream legal files, and must exclude internal data and development secrets.
3. Require all CI jobs on the release commit to pass. Test the archive, not just
   a local path dependency. Release automation reruns the matrix before publishing.

## First public release — intentionally not performed yet

The repository starts with GitHub Internal visibility. No RubyGems version or
release tag is created during preparation. The publishing job refuses to run
while the repository is non-public, and requires manual dispatch from a version tag.

1. Obtain the owner's decision to publish, confirm the RubyGems name is available,
   and change repository visibility to Public. Update README's release-status and
   installation wording and date the changelog in the approved release commit.
2. In the intended RubyGems maintainer account, enable MFA and create a **pending
   trusted publisher** with gem `parkes-payment-icons`, owner `ParkesAI`, repository
   `parkes-payment-icons`, workflow `release.yml`, and environment `release`.
   This step needs the maintainer's RubyGems account; no long-lived API key is needed.
3. Confirm the GitHub `release` environment has the intended required reviewer.
   Agree on continuing maintainers and add appropriate RubyGems owners after the
   initial push. The first publisher becomes an owner of the new gem.
4. Create and push an annotated `vVERSION` tag at the approved, passing commit.
   Manually run **Publish gem** for that tag with `publish=true`. The full CI matrix
   runs first; the protected release job checks the tag matches the gem version,
   builds the archive, authenticates with OIDC, and pushes to RubyGems.org.
5. Verify installation from RubyGems in a clean application and publish release
   notes. Switch Parkes's path dependency to the released version in a separate
   application change. Do not create a second maintained copy in the monorepo.

The local Rakefile intentionally has no `release` or `push` task. Public publishing
is confined to the explicit GitHub workflow. Never overwrite an existing version;
publish a new patch release for corrections.

References: [RubyGems trusted publishing](https://guides.rubygems.org/trusted-publishing/),
[Apache License 2.0](https://www.apache.org/licenses/LICENSE-2.0),
[Rails asset pipelines](https://guides.rubyonrails.org/asset_pipeline.html).
