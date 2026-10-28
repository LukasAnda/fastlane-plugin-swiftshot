# swiftshot plugin

[![fastlane Plugin Badge](https://rawcdn.githack.com/fastlane/fastlane/master/fastlane/assets/plugin-badge.svg)](https://rubygems.org/gems/fastlane-plugin-swiftshot)

Runs [Swiftshot](https://github.com/LukasAnda/swiftshot) from a lane: App Store and Play screenshots
from SwiftUI / UIKit `#Preview`s and Jetpack Compose, Compose Multiplatform and Flutter previews.
Use it in place of `capture_ios_screenshots` (`snapshot`) and `capture_android_screenshots` (`screengrab`).

## Install

```bash
brew install lukasanda/tap/swiftshot    # or install.sh, see the Swiftshot docs
fastlane add_plugin swiftshot
```

## Usage

```ruby
lane :screenshots do
  swiftshot
  upload_to_app_store(skip_binary_upload: true, skip_metadata: true, overwrite_screenshots: true)
end
```

With no options it runs `swiftshot run` in the project root, which reads `swiftshot.json`
(`swiftshot init` writes one). Options set in the lane win over the file.

Screenshots go where `deliver` and `supply` look:

- iOS: `fastlane/screenshots`, like snapshot.
- Android (`platform: "android"` or a `platform :android` lane): `fastlane/metadata/android` with
  the `fastlane` layout, like screengrab.
- `output_directory` in `swiftshot.json` or in the lane overrides both.

Without a `fastlane` folder the defaults are `screenshots` and `metadata`.

The action returns the screenshots folder and sets `SWIFTSHOT_OUTPUT_DIRECTORY`,
`SWIFTSHOT_SCREENSHOT_COUNT` and, like snapshot and screengrab, `SNAPSHOT_SCREENSHOTS_PATH` (iOS)
or `SCREENGRAB_OUTPUT_DIRECTORY` (Android) in `lane_context`. It fails the lane if any screenshot
fails. `capture_preview_screenshots` is an alias.

## Options

All optional. Each can also be set with its environment variable.

| option | env | swiftshot flag |
|---|---|---|
| `binary_path` | `SWIFTSHOT_BINARY_PATH` | default: `swiftshot` on `PATH`, then `~/.swiftshot/bin/swiftshot` |
| `config` | `SWIFTSHOT_CONFIG` | `--config` |
| `project_path` | `SWIFTSHOT_PROJECT_PATH` | folder to run in, default: project root |
| `platform` | `SWIFTSHOT_PLATFORM` | `--platform` (`ios`, `android`) |
| `devices` | `SWIFTSHOT_DEVICES` | `--devices` |
| `languages` | `SWIFTSHOT_LANGUAGES` | `--languages` |
| `ios_versions` | `SWIFTSHOT_IOS_VERSIONS` | `--ios` |
| `appearances` | `SWIFTSHOT_APPEARANCES` | `--appearances` (`light`, `dark`) |
| `dark_mode` | `SWIFTSHOT_DARK_MODE` | `--appearances dark` / `light`, as in snapshot |
| `previews` | `SWIFTSHOT_PREVIEWS` | `--previews` |
| `output_directory` | `SWIFTSHOT_OUTPUT_DIRECTORY` | `--output` |
| `clear_previous_screenshots` | `SWIFTSHOT_CLEAR_PREVIOUS_SCREENSHOTS` | `--clear` when true |
| `frame` | `SWIFTSHOT_FRAME` | `--frame` (`plain`, `appstore` on iOS, `none`) |
| `layout` | `SWIFTSHOT_LAYOUT` | `--layout` (Android: `swiftshot`, `fastlane`) |
| `extra_args` | `SWIFTSHOT_EXTRA_ARGS` | added as is, e.g. `["--scheme", "MyApp", "--no-html"]` |

Everything else (`scheme`, `screens`, `text_sizes`, `modules`…) goes in `swiftshot.json` or
`extra_args`. See [Configuration](https://github.com/LukasAnda/swiftshot/wiki/Configuration) and
[Command line](https://github.com/LukasAnda/swiftshot/wiki/Command-line).

## Migrating

snapshot:

```ruby
# before
capture_ios_screenshots(
  devices: ["iPhone 17 Pro Max", "iPad Pro 13-inch (M5)"],
  languages: ["en-US", "de-DE"],
  dark_mode: true,
  output_directory: "fastlane/screenshots",
  clear_previous_screenshots: true
)

# after
swiftshot(
  devices: ["iPhone 17 Pro Max", "iPad Pro 13-inch (M5)"],
  languages: ["en-US", "de-DE"],
  dark_mode: true,
  output_directory: "fastlane/screenshots",
  clear_previous_screenshots: true
)
```

`ios_version: "26.5"` becomes `ios_versions: ["26.5"]`. `scheme` and `project` / `workspace` go
in `swiftshot.json` (the app scheme, not the UI test scheme).

screengrab:

```ruby
# before
capture_android_screenshots(locales: ["en-US", "de-DE"], clear_previous_screenshots: true)

# after
swiftshot(platform: "android", languages: ["en-US", "de-DE"], clear_previous_screenshots: true)
```

More in [Migrating from fastlane](https://github.com/LukasAnda/swiftshot/wiki/Migrating-from-fastlane).

## Development

```bash
bundle install
bundle exec rake    # rspec and rubocop
```

## License

MIT
