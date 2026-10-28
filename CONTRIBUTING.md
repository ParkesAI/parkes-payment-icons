# Contributing

Open an issue or pull request describing the user-visible change. Keep this gem
focused on Rails asset delivery; payment processing and provider brand mapping
belong in consuming applications.

Run `bin/setup`, then `bundle exec rake test upstream:check compatibility`.
CI covers both asset pipelines across the supported Rails versions. Include a
regression check for behavior changes. Run `git diff --check` before submitting.

Update artwork with the documented `upstream:update` task. Submit artwork changes
to the upstream project first so the gem can retain unchanged, attributable files.
Do not edit vendored files or checksums manually. Run `upstream:verify` after imports.

Contributions intentionally submitted for inclusion are under Apache-2.0 unless
explicitly stated otherwise, as described in section 5 of LICENSE. Submit only work
you are authorized to contribute, including any necessary employer permission.
Retain applicable third-party notices and identify the source of new material.

For a security issue, use GitHub's private vulnerability reporting for this
repository when available; do not disclose sensitive details in a public issue.
