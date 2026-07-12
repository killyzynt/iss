name: "Free Unsigned iOS Export"
on: [push, workflow_dispatch]

# 💡 This environment block forces Node runtime compliance to fix the warning spam!
env:
  FORCE_JAVASCRIPT_ACTIONS_TO_NODE24: true
  ACTIONS_ALLOW_USE_UNSECURE_NODE_VERSION: true

jobs:
  build-ios:
    runs-on: macos-latest
    steps:
      - name: Checkout Source Code
        uses: actions/checkout@v4

      - name: Setup Godot Engine Environment
        uses: chickensoft-games/setup-godot@v2
        with:
          version: 4.6.3.stable

      - name: Initialize Local Workspaces
        run: |
          mkdir -p ios
          mkdir -p build

      - name: Compile and Package iOS Asset Structures
        run: |
          # 💡 Using lowercase "ios" target matching your export preset file definitions
          godot --headless --export-release "ios" ./ios/game.xcodeproj || godot --headless --export-release "iOS" ./ios/game.xcodeproj

      - name: Compress Unsigned App Directory
        run: |
          # Grabs whatever project workspace contents were successfully generated
          zip -r ios_xcode_project.zip ios/

      - name: Upload Exported Files to GitHub
        uses: actions/upload-artifact@v4
        with:
          name: godot-ios-project
          path: ios_xcode_project.zip
