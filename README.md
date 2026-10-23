# BoltEarth iOS SDK — Sample App

A native iOS (Swift / UIKit) app that demonstrates how to integrate and use the [BoltEarth iOS SDK](https://github.com/BOLT-EARTH/bolt-earth-ios-sdk) (`BoltEarthUiSdkCore`).

The whole integration lives in one file, [`ViewController.swift`](BoltEarthTestApp/ViewController.swift), so you can read it top to bottom and copy what you need into your own app.

> **Access note:** The BoltEarth SDK is only for approved and authorised applications. Your app's Bundle Identifier must be whitelisted by the Bolt.Earth team before the SDK flows work. The SDK reads the host app's Bundle Identifier for backend validation and API authorisation.

---

## Prerequisites

| Tool | Required version |
|------|-----------------|
| Xcode | 26.x or later (tested with 26.6) |
| CocoaPods | Any recent version (`sudo gem install cocoapods` or `brew install cocoapods`) |
| iOS Simulator / Device | iOS 17.0+ for this sample |

The SDK itself (`BoltEarthUiSdkCore`) declares a minimum of **iOS 13.0**. This sample sets its own deployment target to **iOS 17.0**. Xcode 27 also requires pods to target iOS 15.0 or later, and the `Podfile` raises every pod to this sample's target (see [Troubleshooting](#troubleshooting)).

You also need these from Bolt.Earth:

- **Client ID**
- **SDK token**
- A **whitelisted Bundle Identifier** for your app

---

## 1. Clone

```bash
git clone https://github.com/BOLT-EARTH/native-sdk-sample-app-ios.git
cd native-sdk-sample-app-ios
```

---

## 2. Install dependencies

```bash
pod install
```

Open the workspace (not the `.xcodeproj`) in Xcode:

```bash
open BoltEarthTestApp.xcworkspace
```

---

## 3. Set your Bundle Identifier and signing

1. Select the **BoltEarthTestApp** target, then **Signing & Capabilities**.
2. Replace the placeholder Bundle Identifier `com.example.boltearthdemo` with the one Bolt.Earth has whitelisted for your app.
3. Choose your **Team**.

If the Bundle Identifier isn't whitelisted, initialisation or SDK flows will fail.

---

## 4. Add your credentials

Open [`BoltEarthTestApp/ViewController.swift`](BoltEarthTestApp/ViewController.swift) and fill in the constants at the top of the file:

```swift
enum BoltEarthDemoConfig {

    /// Client ID issued by Bolt.Earth for your organisation.
    static let clientID = ""            // ← paste your Client ID

    /// SDK token issued by Bolt.Earth for your organisation.
    static let sdkToken = ""            // ← paste your SDK token

    /// Backend environment. Use `.production` for release builds.
    static let environment: BoltEarthSDK.Configuration.Environment = .staging

    /// Whether SDK screens show the host-app header (logo + home button).
    static let showSDKHeader = true
}
```

The text fields on the demo screen are pre-filled from these values, and you can also type new values into the fields at runtime. Nothing is saved to disk.

> **Do not commit real credentials** to a public repository.

---

## 5. Run

Select an iPhone simulator or a connected device in Xcode and press **Run** (⌘R).

---

## 6. Using the demo screen

| Control | What it does |
|---------|--------------|
| **Client ID / SDK token** | Credentials used by **Initialize** (pre-filled from `BoltEarthDemoConfig`) |
| **Language picker** | SDK language: English, Hindi, Tamil, Kannada, Marathi, Telugu |
| **Initialize** | Calls `BoltEarthSDK.initialize(config:)` |
| **Fetch OEM Vehicles** | Loads the vehicle list; pick one in the vehicle picker below it |
| **Current SOC %** *(optional)* | Vehicle state of charge (0–100), passed to the charger flow |
| **Charger ID** *(optional)* | Skips the QR scan when set, and is also used by **Fetch Charger** |
| **Scan QR** | Opens the charger flow (`presentChargerFlow`); needs a selected OEM vehicle |
| **Bookings** | Opens booking history (`presentBookingHistoryFlow`) |
| **Wallet** | Opens the wallet (`presentWalletFlow`) |
| **Fetch Charger** | Fetches the details of the charger ID entered above |
| **Contact Support** | Shows the support contact details from the SDK |
| **Logout** | Ends the SDK session |
| **Colour swatches** | Theme accent colour (`sdkThemeColorHex`) |

Typical order: **Initialize** → **Fetch OEM Vehicles** → select a vehicle → **Scan QR**.

The font preview at the bottom shows whether the bundled Roboto fonts were found.

---

## SDK calls used

| Call | Where |
|------|-------|
| `BoltEarthSDK.initialize(config:)` | `initializeSDK()` |
| `BoltEarthSDK.fetchOEMVehicles(completion:)` | `fetchOEMVehicles()` |
| `BoltEarthSDK.presentChargerFlow(from:chargerId:vehicleMapperKey:initialSOCPercent:shouldShowHeader:)` | `presentChargerFlow()` |
| `BoltEarthSDK.presentBookingHistoryFlow(from:shouldShowHeader:)` | `presentBookingHistory()` |
| `BoltEarthSDK.presentWalletFlow(from:shouldShowHeader:)` | `presentWallet()` |
| `BoltEarthSDK.fetchCharger(byId:completion:)` | `fetchChargerById()` |
| `BoltEarthSDK.fetchContactSupportInfo()` | `showContactSupport()` |
| `BoltEarthSDK.logout(completion:)` | `logout()` |

---

## What your own app needs

The SDK needs these in the host app. This sample already includes them.

**Podfile**

```ruby
platform :ios, '17.0'   # SDK minimum is 13.0; Xcode 27 requires pods at 15.0+
use_frameworks!

target 'YourApp' do
  pod 'BoltEarthUiSdkCore',
    :podspec => 'https://raw.githubusercontent.com/BOLT-EARTH/bolt-earth-ios-sdk/1.1.0/BoltEarthUiSdkCore.podspec'
end
```

Use the official `BoltEarthUiSdkCore.podspec` URL so the correct SDK binaries and dependencies resolve. This sample pins the `1.1.0` tag. Replace `1.1.0` in the URL with `main` to always use the latest release. See the [`Podfile`](Podfile) for the `post_install` block (deployment target, library evolution, HyperSDK `fuse.rb`).

**Info.plist and build settings**

- `CFBundleURLTypes` and `LSApplicationQueriesSchemes` for payment apps (UPI, wallets). See [`Info.plist`](BoltEarthTestApp/Info.plist).
- Usage descriptions (set as build settings in this project):
  - `NSCameraUsageDescription` (QR scan)
  - `NSBluetoothAlwaysUsageDescription` (charger connection)
  - `NSLocationWhenInUseUsageDescription` and `NSLocationAlwaysAndWhenInUseUsageDescription` (nearby chargers and active sessions)
- **Optional fonts:** ship `.ttf` files, list them under `UIAppFonts`, and pass their PostScript names via `sdkRegularFontName`, `sdkSemiBoldFontName` and `sdkBoldFontName`. This sample bundles Roboto in [`SampleFont/`](BoltEarthTestApp/SampleFont).
- **Optional header images:** add `header_logo` and `header_home_icon` to `Assets.xcassets`, and the SDK header uses them.

---

## Project structure

```
BoltEarthTestApp/
  ViewController.swift    # Whole integration: config, SDK calls, demo UI
  AppDelegate.swift
  SceneDelegate.swift
  Info.plist              # URL schemes, fonts
  SampleFont/             # Roboto TTF files (UIAppFonts)
  Base.lproj/             # Storyboards
Podfile                   # BoltEarthUiSdkCore + post_install settings
Podfile.lock
MerchantConfig.txt        # Sample client ID placeholder
```

---

## Troubleshooting

### "Missing credentials" alert on Initialize

`clientID` or `sdkToken` is empty. Set them in `BoltEarthDemoConfig` at the top of `ViewController.swift`, or type them into the fields on screen.

### Initialisation or flows fail with valid credentials

Check that the app's Bundle Identifier has been whitelisted by Bolt.Earth. The SDK validates it against the backend. Confirm the **environment** (`.staging` or `.production`) matches where your credentials were issued.

### "The iOS deployment target 'IPHONEOS_DEPLOYMENT_TARGET' is set to 13.0, but the range of supported deployment target versions is 15.0 to 27.x" (Xcode 27)

A pod still targets an iOS version Xcode no longer supports. The `Podfile` `post_install` block raises every pod target (and the Pods project) to the minimum. Run `pod install` again and clean the build folder (⇧⌘K). If you copy the `post_install` block, make sure the comparison uses your minimum (`< min_ios`), not a lower number.

### OS version is lower than the deployment target

The app target's deployment target is higher than your device's iOS. Check **General → Minimum Deployments** and make sure it isn't set to Xcode's "recommended" value.

### A lot of warnings from third-party pods

Some dependencies (for example SDWebImage and MqttCocoaAsyncSocket) use APIs Apple has deprecated, and Xcode shows warnings for them. They come from those libraries and don't affect behaviour. To hide them for these two pods, add this to your `Podfile` target, with versions matching the SDK:

```ruby
pod 'SDWebImage', '5.21.0', :inhibit_warnings => true
pod 'MqttCocoaAsyncSocket', '1.0.8', :inhibit_warnings => true
```

Or hide warnings for all pods by adding `inhibit_all_warnings!` at the top level of the `Podfile`. Your own app's warnings still appear.

### `pod install` fails

Update CocoaPods (`gem install cocoapods` or `brew upgrade cocoapods`), then run:

```bash
pod repo update
pod install
```

### Fonts show "Not found in this app bundle"

Confirm the `.ttf` files are in the app target and listed under `UIAppFonts` in `Info.plist`, and that the PostScript names in `ViewController.swift` (`Roboto-Regular`, `Roboto-SemiBold`, `Roboto-Bold`) match.
