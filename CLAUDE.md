# Dragonfly

On-the-fly attachment/image processing gem for Rack, Rails and Sinatra. Mature and widely
deployed — prefer small, backwards-compatible changes over refactors.

## Running tests

```sh
bundle install
bundle exec rspec spec                      # full suite, ~6s
bundle exec rspec spec/dragonfly/job_spec.rb  # single file
```

- Requires ImageMagick (`convert`/`identify`) and Ghostscript (`gs`) on the PATH; image specs
  fail confusingly without them.
- `SKIP_FLAKY_TESTS=1` skips the ImageMagick PDF spec, which depends on the system ImageMagick
  security policy (PDF is often disabled on Linux).
- Test log goes to `tmp/test.log`. Sample images/files used by specs live in `samples/`
  (`SAMPLES_DIR` in specs).
- Specs use both `should` and `expect` syntax; match the style of the file you're editing
  (most older specs use `should`).
- Use the `test_app` / `test_imagemagick_app` helpers from `spec/spec_helper.rb`; apps are
  destroyed after each example.

## Compatibility

- Supports old Rubies (officially 2.2+) through Ruby 4.x, plus JRuby. Don't use newer syntax:
  no `it` block param, endless methods, pattern matching, hash shorthand (`{x:}`), numbered
  params, `&.` (2.3+), etc.
- When stdlib gems get unbundled in new Rubies, add them as dependencies (runtime in the
  gemspec, e.g. `ostruct`; dev-only in the `Gemfile`, e.g. `cgi`, `benchmark`, `rdoc`).
- Runtime deps are deliberately minimal (`rack`, `addressable`, `ostruct`).
  Don't add new ones without asking.
- Public API changes need a deprecation path. `lib/dragonfly/spec/data_store_examples.rb` is
  shared examples that third-party data store gems (S3 etc.) run — treat it as public API.

## Architecture

- `Dragonfly::App` (`app.rb`) — named, configurable app instance (`Dragonfly.app`). Holds
  registered processors, generators, analysers, datastore, mime types, and a `Server`.
  Configured via `Configurable` (`configure do ... end`). Plugins/datastores are registered in
  `lib/dragonfly.rb`.
- `Job` (`job.rb`, `job/`) — lazy chain of steps: `fetch`, `fetch_file`, `fetch_url`,
  `generate`, `process`. Serialized into URLs (`serializer.rb`, base64 JSON) and signed with a
  SHA from the app secret. Steps run on `apply`.
- `Content` (`content.rb`) wraps a `TempObject` plus `meta`; it's what processors/generators
  receive and mutate. Analysers read from it.
- `Server` / `JobEndpoint` / `RoutedEndpoint` / `Middleware` — Rack layer. `Server` decodes
  job URLs via `UrlMapper`, verifies SHAs, enforces fetch whitelists (`Whitelist`), and returns
  a `Response`.
- `Model` (`model.rb`, `model/`) — `dragonfly_accessor` for ActiveModel-ish classes;
  `Attachment` stores uid + magic attributes. Rails glue in `railtie.rb` and `rails/`.
- Data stores: `FileDataStore`, `MemoryDataStore` (others are separate gems).
- `ImageMagick` plugin (`image_magick/`) — `thumb`/`encode` processors, `text`/`plain`/`plasma`
  generators, `image_properties` analyser, and `Commands` utilities. Shells out via `Shell`.

## Security

Job params come from URLs and end up in shell commands and response headers. Past CVEs
(CVE-2021-33564, CRLF filename injection in 1.4.2) came from this.

- Validate any new step/processor/generator params with `ParamValidators`
  (`validate!`, `validate_all!`, `is_number`, `is_word`, ...), as `Thumb` and the generators do.
- Always escape shell args via `Shell#escape` / `escape_args`; never interpolate raw params.
- Strip `\r`/`\n` from anything that lands in a header (see `has_filename.rb`, `response.rb`).

## Releasing

- Version lives in `lib/dragonfly/version.rb`; changelog in `History.md` (newest first,
  `# x.y.z (YYYY-MM-DD)` with `## Features` / `## Changes` / `## Fixes`).
- Add a `History.md` entry for user-visible changes, but don't bump the version or run
  `rake release` unless asked.

## Dev helpers

`dev/` has scratch tools: `irbrc.rb` (irb setup with a test app), `test.ru` (rackup app for
manual testing), `rails_template.rb` / `test_rails` (generate a Rails app using the local gem).
