//
//  ViewController.swift
//  BoltEarthTestApp
//
//  Reference integration of the BoltEarth iOS SDK (`BoltEarthUiSdkCore`).
//
//  QUICK START
//  1. Enter the Client ID and SDK token issued to you by Bolt.Earth in
//     `BoltEarthDemoConfig` below (or type them into the fields on screen at runtime).
//  2. Make sure this app's Bundle Identifier has been whitelisted by Bolt.Earth.
//     The SDK reads the host app's Bundle Identifier for backend validation, so
//     flows fail for a Bundle Identifier that has not been configured.
//  3. Run `pod install`, open `BoltEarthTestApp.xcworkspace`, and run the app.
//
//  Typical call order in your own app:
//     BoltEarthSDK.initialize(config:)          -> once per session
//     BoltEarthSDK.fetchOEMVehicles(...)        -> pick the vehicle's `externalKey`
//     BoltEarthSDK.presentChargerFlow(...)      -> QR scan / charger booking
//     BoltEarthSDK.presentBookingHistoryFlow(…) -> user's bookings
//     BoltEarthSDK.presentWalletFlow(...)       -> wallet
//     BoltEarthSDK.logout(...)                  -> end the session
//

import UIKit
import BoltEarthUiSdkCore

// MARK: - Configuration (edit these values)

/// Credentials and SDK options used by this demo.
///
/// Fill in `clientID` and `sdkToken` with the values provided by Bolt.Earth.
/// The text fields on screen are pre-filled from these constants and can still
/// be edited at runtime.
///
/// - Important: Do not commit real credentials to a public repository.
enum BoltEarthDemoConfig {

    static let clientID = "" // Replace

    /// SDK token issued by Bolt.Earth for your organisation.
    static let sdkToken = "" // Replace

    /// Backend environment the SDK talks to. Use `.production` for release builds.
    static let environment: BoltEarthSDK.Configuration.Environment = .staging

    /// Whether the SDK screens show the host-app header (logo + home button).
    static let showSDKHeader = true
}

// MARK: - Optional header images

/// Optional images the SDK can show in its header (`sdkHeaderLogoBase64`, `sdkHeaderHomeIconBase64`).
///
/// Add images with these names to `Assets.xcassets` to use them. If an image is
/// missing, `base64` is `nil` and the SDK uses its default header.
enum SampleImages: String {
    case headerLogo = "header_logo"
    case homeIcon = "header_home_icon"

    var value: UIImage? {
        return UIImage(named: rawValue)
    }

    /// PNG data of the image, base64-encoded as expected by `BoltEarthSDK.Configuration`.
    var base64: String? {
        return value?.pngData()?.base64EncodedString()
    }
}

// MARK: - ViewController

/// Demo screen: configure the SDK (credentials, language, theme, fonts), initialise it,
/// and launch each SDK flow.
class ViewController: UIViewController {

    // MARK: Demo option types

    /// PostScript names of the bundled Roboto fonts. They must be listed under
    /// `UIAppFonts` in Info.plist and are passed to `BoltEarthSDK.Configuration`.
    fileprivate enum RobotoFontNames {
        static let regular = "Roboto-Regular"
        static let bold = "Roboto-Bold"
        static let semiBold = "Roboto-SemiBold"
    }

    /// One entry per SDK font parameter (`sdkRegularFontName`, `sdkSemiBoldFontName`, `sdkBoldFontName`).
    fileprivate enum FontSlot: CaseIterable {
        case regular
        case semiBold
        case bold

        /// Human-readable description shown in the font preview.
        var friendlyTitle: String {
            switch self {
            case .regular: return "Regular — paragraphs & secondary text"
            case .semiBold: return "Semi-bold — subheads & emphasis"
            case .bold: return "Bold — headlines & emphasis"
            }
        }

        var postScriptName: String {
            switch self {
            case .regular: return RobotoFontNames.regular
            case .semiBold: return RobotoFontNames.semiBold
            case .bold: return RobotoFontNames.bold
            }
        }

        /// Name of the `BoltEarthSDK.Configuration` parameter this slot feeds.
        var sdkParameterName: String {
            switch self {
            case .regular: return "`sdkRegularFontName`"
            case .semiBold: return "`sdkSemiBoldFontName`"
            case .bold: return "`sdkBoldFontName`"
            }
        }

        /// System weight used for the preview when the custom font is not available.
        var fallbackSystemWeight: UIFont.Weight {
            switch self {
            case .regular: return .regular
            case .semiBold: return .semibold
            case .bold: return .bold
            }
        }
    }

    /// Accent colours selectable for `sdkThemeColorHex`. The default is blue (`#00AAFF`).
    fileprivate enum ThemeSwatch: Int, CaseIterable {
        case red
        case yellow
        case orange
        case blue

        /// Hex string passed to the SDK.
        var hex: String {
            switch self {
            case .red: return "#FF3B30"
            case .yellow: return "#FFCC00"
            case .orange: return "#FF9500"
            case .blue: return "#00AAFF"
            }
        }

        /// Colour used to draw the swatch on screen.
        var displayColor: UIColor {
            switch self {
            case .red: return UIColor(red: 1, green: 59 / 255, blue: 48 / 255, alpha: 1)
            case .yellow: return UIColor(red: 1, green: 204 / 255, blue: 0, alpha: 1)
            case .orange: return UIColor(red: 1, green: 149 / 255, blue: 0, alpha: 1)
            case .blue: return UIColor(red: 0, green: 170 / 255, blue: 1, alpha: 1)
            }
        }
    }

    /// Languages supported by the SDK. The raw value is the ISO 639-1 (alpha-2) code
    /// passed to `BoltEarthSDK.Configuration.language`.
    fileprivate enum DemoLanguage: String, CaseIterable {
        case english = "en"
        case hindi = "hi"
        case tamil = "ta"
        case kannada = "kn"
        case marathi = "mr"
        case telugu = "te"

        var displayName: String {
            switch self {
            case .english: return "English"
            case .hindi: return "Hindi"
            case .tamil: return "Tamil"
            case .kannada: return "Kannada"
            case .marathi: return "Marathi"
            case .telugu: return "Telugu"
            }
        }

        /// Text shown in the picker, for example "English (en)".
        var pickerTitle: String {
            return "\(displayName) (\(rawValue))"
        }
    }

    /// Text colours for the font preview (higher contrast than the default `label` colour).
    fileprivate enum FontPreviewColors {
        static let body = UIColor(red: 0.06, green: 0.07, blue: 0.11, alpha: 1)
        static let sectionHeading = UIColor(red: 0.16, green: 0.18, blue: 0.24, alpha: 1)
        static let muted = UIColor(red: 0.38, green: 0.40, blue: 0.46, alpha: 1)
        static let success = UIColor(red: 0.12, green: 0.52, blue: 0.32, alpha: 1)
        static let warning = UIColor(red: 0.72, green: 0.45, blue: 0.05, alpha: 1)
    }

    // MARK: Constants

    fileprivate enum Layout {
        static let horizontalPadding: CGFloat = 20
        static let swatchSize: CGFloat = 40
    }

    /// Tag used to find and remove the full-screen text popup.
    private static let textPopupTag = 9_001

    // MARK: Storyboard outlets

    /// Client ID field (defined in `Main.storyboard`; moved into the scroll view at runtime).
    @IBOutlet private weak var textField: UITextField!

    /// Label that shows the font preview (defined in `Main.storyboard`; moved into the scroll view at runtime).
    @IBOutlet private weak var sampleLabel: UILabel!

    // MARK: State

    /// `true` after `BoltEarthSDK.initialize(config:)` has succeeded.
    private(set) var isSDKInitialized = false

    /// Theme colour passed to the SDK. Matches the default selected swatch (blue).
    private var selectedThemeHex: String = ThemeSwatch.blue.hex

    /// Language passed to the SDK; English by default.
    private var selectedLanguage: DemoLanguage = .english {
        didSet { refreshLanguagePicker() }
    }

    /// OEM vehicles returned by `fetchOEMVehicles`.
    private var oemVehicles: [[String: Any]] = []

    /// Vehicle whose `externalKey` is passed to `presentChargerFlow` as the vehicle mapper key.
    private var selectedOEMVehicle: [String: Any]?

    // MARK: UI elements

    /// Client ID input (storyboard outlet under a clearer name).
    private var clientIDTextField: UITextField { textField }

    private let sdkTokenTextField = ViewController.makeInputField(placeholder: "SDK token")
    private let socTextField = ViewController.makeInputField(placeholder: "Current SOC % (0–100, default 0)")
    private let chargerIdTextField = ViewController.makeInputField(placeholder: "Charger ID (e.g. BE1234, BOLT_ABC123)")

    private let initializeButton = ViewController.makeActionButton(title: "Initialize", color: .systemBlue)
    private let launchButton = ViewController.makeActionButton(title: "Scan QR", color: UIColor(red: 0.18, green: 0.80, blue: 0.44, alpha: 1))
    private let bookingListingButton = ViewController.makeActionButton(title: "Bookings", color: .systemIndigo)
    private let walletButton = ViewController.makeActionButton(title: "Wallet", color: UIColor(red: 1, green: 0.6, blue: 0, alpha: 1))
    private let logoutButton = ViewController.makeActionButton(title: "Logout", color: .systemRed)
    private let contactSupportButton = ViewController.makeActionButton(title: "Contact Support", color: UIColor(red: 0.2, green: 0.6, blue: 0.9, alpha: 1))
    private let fetchChargerButton = ViewController.makeActionButton(title: ViewController.fetchChargerTitle, color: UIColor(red: 0, green: 0.55, blue: 0.45, alpha: 1))
    private let fetchVehiclesButton = ViewController.makeActionButton(title: ViewController.fetchVehiclesTitle, color: UIColor(red: 0.3, green: 0.2, blue: 0.7, alpha: 1))

    /// Opens a menu to choose the OEM vehicle passed to `presentChargerFlow`.
    private let oemVehiclePickerButton = ViewController.makePickerButton()

    /// Opens a menu to choose the SDK language.
    private let languagePickerButton = ViewController.makePickerButton()

    private let themeSwatchStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.alignment = .center
        stack.distribution = .equalSpacing
        stack.spacing = 24
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    private let mainScrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.alwaysBounceVertical = true
        scrollView.showsVerticalScrollIndicator = true
        scrollView.keyboardDismissMode = .onDrag
        return scrollView
    }()

    private let scrollContentView: UIView = {
        let contentView = UIView()
        contentView.translatesAutoresizingMaskIntoConstraints = false
        return contentView
    }()

    private static let fetchChargerTitle = "Fetch Charger"
    private static let fetchVehiclesTitle = "Fetch OEM Vehicles"

    // MARK: Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        configureCredentialFields()
        configureFontPreview()
        setupLayout()
        refreshLanguagePicker()
    }

    /// Pre-fills the credential fields from `BoltEarthDemoConfig` and sets up keyboard behaviour.
    private func configureCredentialFields() {
        clientIDTextField.placeholder = "Enter Client ID"
        clientIDTextField.text = BoltEarthDemoConfig.clientID
        clientIDTextField.autocapitalizationType = .none
        clientIDTextField.autocorrectionType = .no
        clientIDTextField.returnKeyType = .done
        clientIDTextField.delegate = self

        sdkTokenTextField.text = BoltEarthDemoConfig.sdkToken
        sdkTokenTextField.delegate = self

        socTextField.delegate = self
        socTextField.keyboardType = .decimalPad
        chargerIdTextField.delegate = self
    }
}

// MARK: - SDK actions

private extension ViewController {

    /// Initialises the SDK with the values currently shown on screen.
    ///
    /// - Returns: `true` if the SDK is ready to use. On failure an alert is shown and `false` is returned.
    @discardableResult
    func initializeSDK() -> Bool {
        view.endEditing(true)
        let clientID = trimmed(clientIDTextField.text)
        let sdkToken = trimmed(sdkTokenTextField.text)

        guard !clientID.isEmpty, !sdkToken.isEmpty else {
            presentAlert(
                title: "Missing credentials",
                message: "Set clientID and sdkToken in BoltEarthDemoConfig (top of ViewController.swift) or type them into the fields above."
            )
            return false
        }

        // Every parameter except `clientID` and `sdkToken` is optional.
        let config = BoltEarthSDK.Configuration(
            clientID: clientID,
            sdkToken: sdkToken,
            environment: BoltEarthDemoConfig.environment,
            language: selectedLanguage.rawValue,
            sdkRegularFontName: RobotoFontNames.regular,
            sdkBoldFontName: RobotoFontNames.bold,
            sdkSemiBoldFontName: RobotoFontNames.semiBold,
            sdkThemeColorHex: selectedThemeHex,
            sdkHeaderLogoBase64: SampleImages.headerLogo.base64,
            sdkHeaderHomeIconBase64: SampleImages.homeIcon.base64
        )

        do {
            try BoltEarthSDK.initialize(config: config)
        } catch let error as BoltEarthSDK.InitializationError {
            presentAlert(message: error.localizedDescription)
            return false
        } catch {
            presentAlert(message: error.localizedDescription)
            return false
        }

        isSDKInitialized = true
        return true
    }

    /// Initialises the SDK on first use. Returns `false` if initialisation failed.
    func ensureSDKInitialized() -> Bool {
        return isSDKInitialized || initializeSDK()
    }

    /// Opens the charger flow (QR scan / booking) for the selected OEM vehicle.
    func presentChargerFlow() {
        guard ensureSDKInitialized() else { return }

        guard let mapperKey = selectedOEMVehicle?["externalKey"] as? String, !mapperKey.isEmpty else {
            presentAlert(message: "Please select an OEM vehicle before launching. Tap \"Fetch OEM Vehicles\" to load the list.")
            return
        }

        // Optional: the vehicle's current state of charge (0–100). Defaults to 0.
        let socText = trimmed(socTextField.text)
        let soc: Float = socText.isEmpty ? 0 : (Float(socText) ?? 0)

        // Optional: skip the QR scan by passing a charger ID.
        let chargerId = trimmed(chargerIdTextField.text)

        do {
            try BoltEarthSDK.presentChargerFlow(
                from: self,
                chargerId: chargerId.isEmpty ? nil : chargerId,
                vehicleMapperKey: mapperKey,
                initialSOCPercent: soc,
                shouldShowHeader: BoltEarthDemoConfig.showSDKHeader
            )
        } catch {
            presentAlert(message: error.localizedDescription)
        }
    }

    /// Opens the user's booking history.
    func presentBookingHistory() {
        guard ensureSDKInitialized() else { return }
        BoltEarthSDK.presentBookingHistoryFlow(from: self, shouldShowHeader: BoltEarthDemoConfig.showSDKHeader)
    }

    /// Opens the wallet.
    func presentWallet() {
        guard ensureSDKInitialized() else { return }
        do {
            try BoltEarthSDK.presentWalletFlow(from: self, shouldShowHeader: BoltEarthDemoConfig.showSDKHeader)
        } catch {
            presentAlert(message: error.localizedDescription)
        }
    }

    /// Shows the support contact details provided by the SDK.
    func showContactSupport() {
        let info = BoltEarthSDK.fetchContactSupportInfo()
        let content = info.map { "\($0.key): \($0.value)" }.sorted().joined(separator: "\n")
        presentTextPopup(title: "Contact Support", content: content)
    }

    /// Ends the SDK session.
    func logout() {
        guard BoltEarthSDK.shared != nil else {
            presentAlert(message: "Initialize the SDK first, then try logout.")
            return
        }
        BoltEarthSDK.logout { [weak self] serverAccepted in
            DispatchQueue.main.async {
                let message = serverAccepted
                    ? "Logout finished: server accepted revoke."
                    : "Local session cleared (no active session or server revoke not confirmed)."
                self?.presentAlert(title: "Logout", message: message)
            }
        }
    }

    /// Fetches the details of the charger whose ID is in the charger ID field.
    /// Requires the SDK to be initialised first (tap "Initialize").
    func fetchChargerById() {
        view.endEditing(true)
        let chargerId = trimmed(chargerIdTextField.text)
        guard !chargerId.isEmpty else {
            presentAlert(message: "Enter a charger ID before fetching.")
            return
        }

        setBusy(true, button: fetchChargerButton, busyTitle: "Fetching…", idleTitle: ViewController.fetchChargerTitle)
        do {
            try BoltEarthSDK.fetchCharger(byId: chargerId) { [weak self] response in
                DispatchQueue.main.async {
                    guard let self else { return }
                    self.setBusy(false, button: self.fetchChargerButton, busyTitle: "Fetching…", idleTitle: ViewController.fetchChargerTitle)
                    let status = response["status"] as? Int ?? 0
                    self.presentTextPopup(title: "Charger (\(status))", content: self.prettyPrinted(response))
                }
            }
        } catch {
            // The request was rejected before it started (for example, the SDK is not initialised).
            setBusy(false, button: fetchChargerButton, busyTitle: "Fetching…", idleTitle: ViewController.fetchChargerTitle)
            presentAlert(message: error.localizedDescription)
        }
    }

    /// Fetches the OEM vehicle list and selects the first vehicle if none is selected yet.
    /// Requires the SDK to be initialised first (tap "Initialize").
    func fetchOEMVehicles() {
        view.endEditing(true)

        setBusy(true, button: fetchVehiclesButton, busyTitle: "Fetching…", idleTitle: ViewController.fetchVehiclesTitle)
        BoltEarthSDK.fetchOEMVehicles { [weak self] vehicles in
            DispatchQueue.main.async {
                guard let self else { return }
                self.setBusy(false, button: self.fetchVehiclesButton, busyTitle: "Fetching…", idleTitle: ViewController.fetchVehiclesTitle)

                guard !vehicles.isEmpty else {
                    self.presentAlert(message: "No OEM vehicles returned. Make sure the SDK is initialized.")
                    return
                }

                self.oemVehicles = vehicles
                if self.selectedOEMVehicle == nil, let first = vehicles.first {
                    self.selectOEMVehicle(first)
                } else {
                    self.refreshOEMVehiclePicker()
                }
                self.presentTextPopup(title: "OEM Vehicles (\(vehicles.count))", content: self.prettyPrinted(vehicles))
            }
        }
    }

    /// Switches a button between its idle and "busy" (disabled, "Fetching…") state.
    func setBusy(_ isBusy: Bool, button: UIButton, busyTitle: String, idleTitle: String) {
        button.isEnabled = !isBusy
        button.configuration?.title = isBusy ? busyTitle : idleTitle
    }

    /// Pretty-prints a JSON-compatible value, falling back to `description` if it cannot be encoded.
    func prettyPrinted(_ value: Any) -> String {
        guard JSONSerialization.isValidJSONObject(value),
              let data = try? JSONSerialization.data(withJSONObject: value, options: .prettyPrinted),
              let string = String(data: data, encoding: .utf8) else {
            return "\(value)"
        }
        return string
    }

    func trimmed(_ text: String?) -> String {
        return text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }
}

// MARK: - Button actions

private extension ViewController {

    @objc func initializeTapped() { initializeSDK() }
    @objc func scanQRTapped() { presentChargerFlow() }
    @objc func bookingsTapped() { presentBookingHistory() }
    @objc func walletTapped() { presentWallet() }
    @objc func logoutTapped() { logout() }
    @objc func fetchVehiclesTapped() { fetchOEMVehicles() }
    @objc func fetchChargerTapped() { fetchChargerById() }
    @objc func contactSupportTapped() { showContactSupport() }

    @objc func themeSwatchTapped(_ sender: UITapGestureRecognizer) {
        guard let swatchView = sender.view,
              let swatch = ThemeSwatch(rawValue: swatchView.tag) else { return }
        applyThemeSwatchSelection(swatch, animated: true)
    }

    @objc func dismissTextPopup() {
        guard let overlay = view.viewWithTag(ViewController.textPopupTag) else { return }
        UIView.animate(withDuration: 0.2, animations: { overlay.alpha = 0 }) { _ in
            overlay.removeFromSuperview()
        }
    }

    /// Shown when the vehicle picker is tapped before any vehicles have been loaded.
    @objc func presentNoVehiclesAlert() {
        presentAlert(message: "No OEM vehicles loaded. Tap \"Fetch OEM Vehicles\" first.")
    }
}

// MARK: - Pickers (language, OEM vehicle, theme)

private extension ViewController {

    // Language

    func refreshLanguagePicker() {
        let title = selectedLanguage.pickerTitle
        languagePickerButton.configuration?.title = title
        languagePickerButton.accessibilityLabel = "SDK language: \(title)"

        let actions = DemoLanguage.allCases.map { language in
            UIAction(title: language.pickerTitle, state: language == selectedLanguage ? .on : .off) { [weak self] _ in
                self?.selectedLanguage = language
            }
        }
        languagePickerButton.menu = UIMenu(title: "SDK language", children: actions)
        languagePickerButton.showsMenuAsPrimaryAction = true
    }

    // OEM vehicle

    func selectOEMVehicle(_ vehicle: [String: Any]) {
        selectedOEMVehicle = vehicle
        refreshOEMVehiclePicker()
    }

    /// Display name such as "Company Model · Type".
    func oemVehicleDisplayName(_ vehicle: [String: Any]) -> String {
        let model = vehicle["model"] as? String ?? "Unknown Model"
        let company = vehicle["company"] as? String ?? ""
        let type = vehicle["type"] as? String ?? ""
        let name = company.isEmpty ? model : "\(company) \(model)"
        return type.isEmpty ? name : "\(name) · \(type)"
    }

    /// Updates the picker title and menu to match `oemVehicles` and `selectedOEMVehicle`.
    func refreshOEMVehiclePicker() {
        if let selected = selectedOEMVehicle {
            oemVehiclePickerButton.configuration?.title = oemVehicleDisplayName(selected)
            oemVehiclePickerButton.configuration?.baseForegroundColor = .label
        } else {
            oemVehiclePickerButton.configuration?.title = "Select OEM Vehicle"
            oemVehiclePickerButton.configuration?.baseForegroundColor = .systemGray
        }
        oemVehiclePickerButton.accessibilityLabel = "OEM vehicle: \(oemVehiclePickerButton.configuration?.title ?? "")"

        // Nothing to choose from yet: tapping explains how to load the list instead of opening a menu.
        guard !oemVehicles.isEmpty else {
            oemVehiclePickerButton.menu = nil
            oemVehiclePickerButton.showsMenuAsPrimaryAction = false
            oemVehiclePickerButton.removeTarget(nil, action: nil, for: .touchUpInside)
            oemVehiclePickerButton.addTarget(self, action: #selector(presentNoVehiclesAlert), for: .touchUpInside)
            return
        }

        let selectedKey = selectedOEMVehicle?["externalKey"] as? String
        let actions = oemVehicles.map { vehicle -> UIAction in
            let key = vehicle["externalKey"] as? String ?? ""
            return UIAction(title: oemVehicleDisplayName(vehicle), state: key == selectedKey ? .on : .off) { [weak self] _ in
                self?.selectOEMVehicle(vehicle)
            }
        }
        oemVehiclePickerButton.menu = UIMenu(title: "OEM Vehicle", children: actions)
        oemVehiclePickerButton.showsMenuAsPrimaryAction = true
        oemVehiclePickerButton.removeTarget(self, action: #selector(presentNoVehiclesAlert), for: .touchUpInside)
    }

    // Theme

    /// Stores the chosen theme colour and enlarges the selected swatch.
    func applyThemeSwatchSelection(_ swatch: ThemeSwatch, animated: Bool) {
        selectedThemeHex = swatch.hex
        let selectedTransform = CGAffineTransform(scaleX: 1.2, y: 1.2)
        let updates = { [weak self] in
            guard let self else { return }
            for swatchView in self.themeSwatchStack.arrangedSubviews {
                swatchView.transform = swatchView.tag == swatch.rawValue ? selectedTransform : .identity
            }
        }
        if animated {
            UIView.animate(
                withDuration: 0.22,
                delay: 0,
                usingSpringWithDamping: 0.78,
                initialSpringVelocity: 0.4,
                options: [.allowUserInteraction],
                animations: updates
            )
        } else {
            updates()
        }
    }
}

// MARK: - Font preview

private extension ViewController {

    /// Shows each SDK font slot with a sample line and whether the bundled font was found.
    func configureFontPreview() {
        let previewPointSize: CGFloat = 26
        let samplePhrase = "The quick brown fox jumps over lazy dogs."

        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 14, weight: .semibold),
            .foregroundColor: FontPreviewColors.sectionHeading
        ]
        let technicalAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.monospacedSystemFont(ofSize: 11, weight: .regular),
            .foregroundColor: FontPreviewColors.muted
        ]

        let result = NSMutableAttributedString()

        for slot in FontSlot.allCases {
            // `UIFont(name:size:)` returns nil if the .ttf is missing or not listed under UIAppFonts.
            let embeddedFont = UIFont(name: slot.postScriptName, size: previewPointSize)
            let displayFont = embeddedFont ?? UIFont.systemFont(ofSize: previewPointSize, weight: slot.fallbackSystemWeight)

            result.append(NSAttributedString(string: slot.friendlyTitle + "\n", attributes: titleAttributes))
            result.append(NSAttributedString(string: samplePhrase + "\n", attributes: [
                .font: displayFont,
                .foregroundColor: FontPreviewColors.body
            ]))

            let statusText: String
            let statusColor: UIColor
            if embeddedFont != nil {
                statusText = "Loaded successfully. The SDK can use this style.\n"
                statusColor = FontPreviewColors.success
            } else {
                statusText = "Not found in this app bundle. The line above uses the system font as a stand-in until you add the .ttf and list it under UIAppFonts.\n"
                statusColor = FontPreviewColors.warning
            }
            result.append(NSAttributedString(string: statusText, attributes: [
                .font: UIFont.systemFont(ofSize: 12, weight: .medium),
                .foregroundColor: statusColor
            ]))

            result.append(NSAttributedString(
                string: "\(slot.sdkParameterName) → \(slot.postScriptName)\n\n",
                attributes: technicalAttributes
            ))
        }

        sampleLabel.attributedText = result
        sampleLabel.textColor = FontPreviewColors.body
        sampleLabel.numberOfLines = 0
        sampleLabel.textAlignment = .left
        sampleLabel.setContentCompressionResistancePriority(.required, for: .vertical)
    }
}

// MARK: - Layout

private extension ViewController {

    /// Builds the screen: a scroll view holding the credential fields, pickers, buttons,
    /// theme swatches and the font preview.
    func setupLayout() {
        let flowButtonsRow = makeButtonRow(launchButton, bookingListingButton)
        let accountButtonsRow = makeButtonRow(walletButton, logoutButton)
        guard let fontPreviewLabel = sampleLabel else { return }

        // Scroll container.
        view.addSubview(mainScrollView)
        mainScrollView.addSubview(scrollContentView)
        NSLayoutConstraint.activate([
            mainScrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            mainScrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mainScrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            mainScrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            scrollContentView.topAnchor.constraint(equalTo: mainScrollView.contentLayoutGuide.topAnchor),
            scrollContentView.leadingAnchor.constraint(equalTo: mainScrollView.contentLayoutGuide.leadingAnchor),
            scrollContentView.trailingAnchor.constraint(equalTo: mainScrollView.contentLayoutGuide.trailingAnchor),
            scrollContentView.bottomAnchor.constraint(equalTo: mainScrollView.contentLayoutGuide.bottomAnchor),
            scrollContentView.widthAnchor.constraint(equalTo: mainScrollView.frameLayoutGuide.widthAnchor)
        ])

        // Move the storyboard views into the scroll content (this drops their storyboard constraints).
        clientIDTextField.removeFromSuperview()
        fontPreviewLabel.removeFromSuperview()

        [clientIDTextField, sdkTokenTextField, languagePickerButton, initializeButton,
         flowButtonsRow, accountButtonsRow, fetchVehiclesButton, oemVehiclePickerButton,
         socTextField, chargerIdTextField, fetchChargerButton, contactSupportButton,
         themeSwatchStack, fontPreviewLabel].forEach { scrollContentView.addSubview($0) }

        addThemeSwatches()

        let pad = Layout.horizontalPadding
        NSLayoutConstraint.activate([
            clientIDTextField.topAnchor.constraint(equalTo: scrollContentView.topAnchor, constant: 20),
            clientIDTextField.leadingAnchor.constraint(equalTo: scrollContentView.leadingAnchor, constant: pad),
            clientIDTextField.trailingAnchor.constraint(equalTo: scrollContentView.trailingAnchor, constant: -pad),
            clientIDTextField.heightAnchor.constraint(equalToConstant: 40),

            sdkTokenTextField.topAnchor.constraint(equalTo: clientIDTextField.bottomAnchor, constant: 12),
            sdkTokenTextField.leadingAnchor.constraint(equalTo: clientIDTextField.leadingAnchor),
            sdkTokenTextField.trailingAnchor.constraint(equalTo: clientIDTextField.trailingAnchor),
            sdkTokenTextField.heightAnchor.constraint(equalToConstant: 40),

            languagePickerButton.topAnchor.constraint(equalTo: sdkTokenTextField.bottomAnchor, constant: 10),
            languagePickerButton.leadingAnchor.constraint(equalTo: clientIDTextField.leadingAnchor),
            languagePickerButton.trailingAnchor.constraint(equalTo: clientIDTextField.trailingAnchor),
            languagePickerButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 40),

            initializeButton.topAnchor.constraint(equalTo: languagePickerButton.bottomAnchor, constant: 20),
            initializeButton.centerXAnchor.constraint(equalTo: scrollContentView.centerXAnchor),

            flowButtonsRow.topAnchor.constraint(equalTo: initializeButton.bottomAnchor, constant: 16),
            flowButtonsRow.leadingAnchor.constraint(equalTo: clientIDTextField.leadingAnchor),
            flowButtonsRow.trailingAnchor.constraint(equalTo: clientIDTextField.trailingAnchor),

            accountButtonsRow.topAnchor.constraint(equalTo: flowButtonsRow.bottomAnchor, constant: 12),
            accountButtonsRow.leadingAnchor.constraint(equalTo: clientIDTextField.leadingAnchor),
            accountButtonsRow.trailingAnchor.constraint(equalTo: clientIDTextField.trailingAnchor),

            fetchVehiclesButton.topAnchor.constraint(equalTo: accountButtonsRow.bottomAnchor, constant: 12),
            fetchVehiclesButton.leadingAnchor.constraint(equalTo: clientIDTextField.leadingAnchor),
            fetchVehiclesButton.trailingAnchor.constraint(equalTo: clientIDTextField.trailingAnchor),

            oemVehiclePickerButton.topAnchor.constraint(equalTo: fetchVehiclesButton.bottomAnchor, constant: 10),
            oemVehiclePickerButton.leadingAnchor.constraint(equalTo: clientIDTextField.leadingAnchor),
            oemVehiclePickerButton.trailingAnchor.constraint(equalTo: clientIDTextField.trailingAnchor),
            oemVehiclePickerButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 40),

            socTextField.topAnchor.constraint(equalTo: oemVehiclePickerButton.bottomAnchor, constant: 16),
            socTextField.leadingAnchor.constraint(equalTo: clientIDTextField.leadingAnchor),
            socTextField.trailingAnchor.constraint(equalTo: clientIDTextField.trailingAnchor),
            socTextField.heightAnchor.constraint(equalToConstant: 40),

            chargerIdTextField.topAnchor.constraint(equalTo: socTextField.bottomAnchor, constant: 10),
            chargerIdTextField.leadingAnchor.constraint(equalTo: clientIDTextField.leadingAnchor),
            chargerIdTextField.trailingAnchor.constraint(equalTo: clientIDTextField.trailingAnchor),
            chargerIdTextField.heightAnchor.constraint(equalToConstant: 40),

            fetchChargerButton.topAnchor.constraint(equalTo: chargerIdTextField.bottomAnchor, constant: 10),
            fetchChargerButton.leadingAnchor.constraint(equalTo: clientIDTextField.leadingAnchor),
            fetchChargerButton.trailingAnchor.constraint(equalTo: clientIDTextField.trailingAnchor),

            contactSupportButton.topAnchor.constraint(equalTo: fetchChargerButton.bottomAnchor, constant: 12),
            contactSupportButton.leadingAnchor.constraint(equalTo: clientIDTextField.leadingAnchor),
            contactSupportButton.trailingAnchor.constraint(equalTo: clientIDTextField.trailingAnchor),

            themeSwatchStack.topAnchor.constraint(equalTo: contactSupportButton.bottomAnchor, constant: 28),
            themeSwatchStack.centerXAnchor.constraint(equalTo: scrollContentView.centerXAnchor),
            themeSwatchStack.widthAnchor.constraint(lessThanOrEqualTo: scrollContentView.widthAnchor, constant: -pad * 2),

            fontPreviewLabel.topAnchor.constraint(equalTo: themeSwatchStack.bottomAnchor, constant: 24),
            fontPreviewLabel.leadingAnchor.constraint(equalTo: clientIDTextField.leadingAnchor),
            fontPreviewLabel.trailingAnchor.constraint(equalTo: clientIDTextField.trailingAnchor),
            fontPreviewLabel.bottomAnchor.constraint(equalTo: scrollContentView.bottomAnchor, constant: -32)
        ])

        connectButtonActions()
        refreshOEMVehiclePicker()
    }

    /// Adds one tappable colour swatch per `ThemeSwatch` and selects the default (blue).
    func addThemeSwatches() {
        for swatch in ThemeSwatch.allCases {
            let swatchView = UIView()
            swatchView.backgroundColor = swatch.displayColor
            swatchView.layer.cornerRadius = 6
            swatchView.layer.masksToBounds = true
            swatchView.tag = swatch.rawValue
            swatchView.translatesAutoresizingMaskIntoConstraints = false
            swatchView.widthAnchor.constraint(equalToConstant: Layout.swatchSize).isActive = true
            swatchView.heightAnchor.constraint(equalToConstant: Layout.swatchSize).isActive = true
            swatchView.isUserInteractionEnabled = true
            swatchView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(themeSwatchTapped(_:))))
            themeSwatchStack.addArrangedSubview(swatchView)
        }
        themeSwatchStack.layoutMargins = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        themeSwatchStack.isLayoutMarginsRelativeArrangement = true
        applyThemeSwatchSelection(.blue, animated: false)
    }

    func connectButtonActions() {
        initializeButton.addTarget(self, action: #selector(initializeTapped), for: .touchUpInside)
        launchButton.addTarget(self, action: #selector(scanQRTapped), for: .touchUpInside)
        bookingListingButton.addTarget(self, action: #selector(bookingsTapped), for: .touchUpInside)
        walletButton.addTarget(self, action: #selector(walletTapped), for: .touchUpInside)
        logoutButton.addTarget(self, action: #selector(logoutTapped), for: .touchUpInside)
        fetchVehiclesButton.addTarget(self, action: #selector(fetchVehiclesTapped), for: .touchUpInside)
        fetchChargerButton.addTarget(self, action: #selector(fetchChargerTapped), for: .touchUpInside)
        contactSupportButton.addTarget(self, action: #selector(contactSupportTapped), for: .touchUpInside)
    }

    /// Two equally wide buttons side by side.
    func makeButtonRow(_ leading: UIButton, _ trailing: UIButton) -> UIStackView {
        let stack = UIStackView(arrangedSubviews: [leading, trailing])
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }
}

// MARK: - Alerts and popups

private extension ViewController {

    func presentAlert(title: String = "Validation", message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    /// Shows a full-screen card with scrollable monospaced text (used for JSON responses).
    func presentTextPopup(title: String, content: String) {
        let overlay = UIView()
        overlay.backgroundColor = UIColor.black.withAlphaComponent(0.55)
        overlay.translatesAutoresizingMaskIntoConstraints = false
        overlay.tag = ViewController.textPopupTag
        view.addSubview(overlay)

        let card = UIView()
        card.backgroundColor = .systemBackground
        card.layer.cornerRadius = 16
        card.layer.masksToBounds = true
        card.translatesAutoresizingMaskIntoConstraints = false
        overlay.addSubview(card)

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(titleLabel)

        let closeButton = UIButton(type: .system)
        closeButton.setTitle("Close", for: .normal)
        closeButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.addTarget(self, action: #selector(dismissTextPopup), for: .touchUpInside)
        card.addSubview(closeButton)

        let textView = UITextView()
        textView.text = content
        textView.isEditable = false
        textView.font = UIFont.monospacedSystemFont(ofSize: 12, weight: .regular)
        textView.backgroundColor = .clear
        textView.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(textView)

        NSLayoutConstraint.activate([
            overlay.topAnchor.constraint(equalTo: view.topAnchor),
            overlay.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            overlay.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            overlay.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            card.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 40),
            card.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            card.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            card.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -40),

            titleLabel.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: closeButton.leadingAnchor, constant: -8),

            closeButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            closeButton.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),

            textView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
            textView.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 8),
            textView.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -8),
            textView.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16)
        ])

        overlay.alpha = 0
        UIView.animate(withDuration: 0.25) { overlay.alpha = 1 }
    }
}

// MARK: - View factories

private extension ViewController {

    /// Rounded, filled button used for every SDK action.
    static func makeActionButton(title: String, color: UIColor) -> UIButton {
        var config = UIButton.Configuration.filled()
        config.title = title
        config.baseBackgroundColor = color
        config.baseForegroundColor = .white
        config.cornerStyle = .fixed
        config.background.cornerRadius = 14
        config.contentInsets = NSDirectionalEdgeInsets(top: 14, leading: 32, bottom: 14, trailing: 32)
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { attributes in
            var attributes = attributes
            attributes.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
            return attributes
        }

        let button = UIButton(configuration: config)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }

    /// Drop-down style button that presents a `UIMenu` when tapped.
    static func makePickerButton() -> UIButton {
        var config = UIButton.Configuration.plain()
        config.baseForegroundColor = .label
        config.background.backgroundColor = .secondarySystemBackground
        config.background.cornerRadius = 6
        config.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 12, bottom: 10, trailing: 36)
        config.titleLineBreakMode = .byTruncatingTail
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { attributes in
            var attributes = attributes
            attributes.font = UIFont.systemFont(ofSize: 14, weight: .medium)
            return attributes
        }

        let button = UIButton(configuration: config)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.contentHorizontalAlignment = .leading
        return button
    }

    /// Plain text input used for the credential, SOC and charger ID fields.
    static func makeInputField(placeholder: String) -> UITextField {
        let field = UITextField()
        field.translatesAutoresizingMaskIntoConstraints = false
        field.borderStyle = .roundedRect
        field.placeholder = placeholder
        field.font = UIFont.systemFont(ofSize: 14)
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        field.spellCheckingType = .no
        field.smartDashesType = .no
        field.smartQuotesType = .no
        field.returnKeyType = .done
        // The system clear button can crash in debug on iOS 26 (`_UILiquidLensView`) when its geometry is invalid during layout.
        if #available(iOS 26.0, *) {
            field.clearButtonMode = .never
        } else {
            field.clearButtonMode = .whileEditing
        }
        return field
    }
}

// MARK: - UITextFieldDelegate

extension ViewController: UITextFieldDelegate {

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        view.endEditing(true)
        return true
    }
}
