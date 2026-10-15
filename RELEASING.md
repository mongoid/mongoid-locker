# Releasing Mongoid::Locker

## Prepare

Use the upstream checkout on a clean `master`, verify `origin` points to `mongoid/mongoid-locker`, and run `git pull --ff-only`. Review existing CI results for supported platforms. Use patch versions for fixes, minor versions for backward-compatible features, and major versions for breaking changes.

Set the version in `lib/mongoid/locker/version.rb`, date its section in `CHANGELOG.md` using `YYYY-MM-DD`, and remove that section's contribution placeholder.

```sh
bundle install
bundle exec rspec
bundle exec rubocop
git add CHANGELOG.md lib/mongoid/locker/version.rb RELEASING.md
git commit -m "Preparing for release, 2.3.0."
git push origin master
```

Do not wait for the preparation commit's CI checks before publishing.

## Publish RubyGems and GitHub

```sh
bundle exec rake release
```

Complete RubyGems MFA when requested. This builds the gem, pushes the release tag, and publishes to RubyGems. If interrupted, inspect the existing tag and published version before retrying. Never move a published tag. If only publication is missing, run `gem push pkg/mongoid-locker-2.3.0.gem` with a fresh MFA code.

A tag is not a GitHub release. After verifying RubyGems publication, create a matching release with the changelog notes:

```sh
version=2.3.0
notes="$(mktemp)"
awk -v version="$version" '
  /^### / {
    if (found) exit
    if ($2 == version) found = 1
    next
  }
  found { print }
' CHANGELOG.md > "$notes"
gh release create "v$version" --repo mongoid/mongoid-locker --verify-tag --title "$version" --notes-file "$notes" --latest
rm "$notes"
curl --fail --silent --show-error "https://rubygems.org/api/v2/rubygems/mongoid-locker/versions/$version.json"
gh release view "v$version" --repo mongoid/mongoid-locker
```

Verify both the published gem and non-draft GitHub release.

## Prepare the Next Version

Increment the development patch version in `lib/mongoid/locker/version.rb`, for example to `2.3.1`. Add `### 2.3.1 (Next)` and a contribution placeholder above the released changelog section. Commit and push these changes to `master`, leaving the release tag unchanged.
