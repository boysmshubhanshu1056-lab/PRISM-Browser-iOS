# PRISM Browser — starter project

A Safari-inspired iPad browser starter with Google Search, tabs, bookmarks, and a ZIP-file picker prototype.

## Important limitations

- Uploading this repository to GitHub does **not** automatically create an installable iPad app.
- This is an iOS/Xcode starter project. To build and install it, you need a Mac with Xcode (or a compatible cloud Mac build service) and Apple signing for installation on a real iPad.
- The ZIP picker currently accepts a ZIP file and reports its name/size. It does **not** execute browser extensions.
- Real Chrome/Firefox extension support requires a compatible extension runtime and API implementation. A ZIP import button alone cannot provide that, and compatibility cannot be guaranteed for every extension.
- GitHub Actions can run checks, but building an installable, signed IPA requires signing assets and configuration.

## Project contents

- `PRISM/PRISMApp.swift` — app entry point
- `PRISM/BrowserView.swift` — Safari-inspired interface and WebKit browser
- `PRISM/Info.plist` — app configuration
- `.github/workflows/ci.yml` — basic repository checks

## Build on a Mac

1. Install Xcode from the Mac App Store.
2. Create a new iOS App project in Xcode named `PRISM`, using SwiftUI and Swift.
3. Replace the generated Swift source with the files in `PRISM/`.
4. In Xcode, set a unique Bundle Identifier and select your Apple development team under **Signing & Capabilities**.
5. Choose an iPad simulator or your connected iPad, then press **Run**.

If you want, the next step is to turn this starter into a complete Xcode project with assets, tests, and a properly configured build pipeline.

## Default search

The address field treats text without a URL scheme as a Google search and opens `https://www.google.com/search?q=...`.
