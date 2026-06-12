# Screenshot capture flow

Real captures from the iOS Simulator via an integration-test driver (no mockups).

## Steps

1. Boot the simulator:
   ```bash
   xcrun simctl boot "iPhone 17 Pro"
   open -a Simulator
   ```
2. Scaffold the iOS platform folder (only needed if `ios/` is missing) and get
   dependencies:
   ```bash
   flutter create . --platforms=ios --project-name flutter_whatsapp_voice_agent
   flutter pub get
   ```
3. Drive the screenshot test:
   ```bash
   flutter drive \
     --driver test_driver/integration_test.dart \
     --target integration_test/screenshot_test.dart \
     -d "iPhone 17 Pro"
   ```
4. Build the demo GIF from the PNGs:
   ```bash
   cd screenshots
   ffmpeg -y -framerate 1 -pattern_type glob -i '*.png' \
     -vf "scale=320:-1:flags=lanczos,split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse" \
     -loop 0 demo.gif
   ```

PNGs + `demo.gif` are written to `screenshots/` and embedded in `README.md`.

## How it works

- `test_driver/integration_test.dart` - `integrationDriver(onScreenshot:)` writes
  each PNG to `screenshots/<name>.png`.
- `integration_test/screenshot_test.dart` - pumps the full app
  (`MaterialApp.router` with the real `appRouter`), which boots straight onto the
  Dashboard backed by the seeded call history in `CallsController`. The test then:
  1. captures `01-dashboard` (stats strip + seeded calls Marta Reyes, Devon Park),
  2. taps the `Marta Reyes` call tile and captures `02-call-detail` (meta card,
     mock player, Claude AI summary with action items, and the chat transcript),
  3. taps the app-bar Back button, then the Settings action, and captures
     `03-settings` (WhatsApp number, greeting, agent prompt, dark-mode toggle).
- Each shot calls `binding.convertFlutterSurfaceToImage()` +
  `tester.pumpAndSettle()` + `binding.takeScreenshot('NN-name')`.
