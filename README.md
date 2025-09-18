# Matatu Cash Collection App

Matatu is a Flutter application for digitising cash collection and reconciliation workflows for public transport fleets. The app is optimised for agents working in the field: it stores transactions locally, synchronises with a central API when connectivity is available, and prints passenger receipts through portable Bluetooth thermal printers.

## Features

- **Multi-client deployment** – Tenant-specific settings (API host, theming, branding and behaviours) are described in `assets/config.json` and mapped to client implementations under `lib/providers/clients/`, allowing the same codebase to service different bus companies.【F:assets/config.json†L1-L18】【F:lib/providers/AppConfig.dart†L1-L96】【F:lib/providers/clients/Citihoppa.dart†L31-L120】
- **Offline-first transaction capture** – Field data is cached with `sqflite`; synchronisation routines push headers and transaction rows once a connection is restored.【F:lib/providers/db.dart†L1-L137】【F:lib/init.dart†L62-L144】
- **Vehicle, crew and revenue dashboards** – Client controllers expose vehicle collections, crew assignments and reporting widgets tailored to operational roles.【F:lib/controllers/main.dart†L24-L142】【F:lib/providers/clients/Citihoppa.dart†L75-L188】
- **Receipt printing over Bluetooth** – Built-in Bluetooth scanning and printer management produce ESC/POS receipts from any supported portable printer.【F:lib/bluetooth/bluetoothManager.dart†L1-L155】【F:lib/providers/client.dart†L108-L188】
- **In-app update delivery** – Optional OTA updates download APKs from the configured update host and guide the agent through installation.【F:lib/utils/updater.dart†L1-L100】

## Repository structure

| Path | Purpose |
| --- | --- |
| `lib/` | Application source organised by feature area (controllers, models, pages, providers, utilities). |
| `assets/` | Client configuration JSON and tenant-specific branding assets bundled with the app.【F:assets/config.json†L1-L18】 |
| `lib/network/results/` | Response wrappers shared by models when parsing paginated API payloads.【F:lib/network/results/results.dart†L1-L60】 |
| `trimline_*` | Historical brand-specific Flutter applications that share data models with the main app. They can be referenced for client-specific UI variants but are not part of the default build. |

## Prerequisites

- Flutter SDK `>=3.1.2 <4.0.0` (check with `flutter --version`).【F:pubspec.yaml†L1-L71】
- Dart-enabled IDE such as Android Studio, VS Code or IntelliJ.
- Android SDK / Xcode tooling depending on the target platform.
- Access to the Matatu API and credentials issued by your organisation.

## Getting started

1. **Clone the repository**
   ```bash
   git clone https://example.com/matatu.git
   cd Matatu
   ```
2. **Install dependencies**
   ```bash
   flutter pub get
   ```
3. **(Optional) Generate JSON serialisers** – Run this step if you change any of the `json_serializable` models.
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```
4. **Run the app**
   ```bash
   flutter run
   ```
5. **Analyse the project**
   ```bash
   flutter analyze
   ```

For iOS builds, open `ios/Runner.xcworkspace` in Xcode after running `pod install` inside the `ios` folder. macOS, Windows and Linux targets follow the standard Flutter desktop workflow.

## Configuration

### Client catalog

- Each client entry in `assets/config.json` declares the API base URL, identifiers and theme colours that appear in the UI.【F:assets/config.json†L1-L18】
- To add a new tenant, define the configuration JSON and create a matching class in `lib/providers/clients/` extending `BaseClients`. Initialise any tenant-specific controllers inside the override of `init()`.【F:lib/providers/AppConfig.dart†L63-L96】【F:lib/providers/clients/Citihoppa.dart†L49-L86】

### API and authentication

- `ApiClient` reads the active configuration and forwards REST calls with the `X-Client-Identifier` header to the backend.【F:lib/network/Apis.dart†L1-L58】
- API secrets and encryption keys should be loaded from secure storage at runtime; do not embed production credentials in source control.

### Local database and sync

- `db_Provider` manages a single `sqflite` database named `Mbranch`, creating and migrating tables for vehicles, agents, transactions and supporting metadata.【F:lib/providers/db.dart†L1-L137】
- Startup routines register controllers, request background data refreshes and queue uploads for pending headers and transaction rows.【F:lib/init.dart†L62-L190】

### Bluetooth and permissions

- Android builds request location and Bluetooth permissions before initialisation so paired printers can be discovered.【F:lib/main.dart†L62-L99】
- The `BluetoothManager` controller scans for available printers, tracks the selected device and exposes helpers for printing receipts.【F:lib/bluetooth/bluetoothManager.dart†L49-L132】

### Updates

- When an `updateUrl` is specified in the client configuration, the `UpdateController` downloads `update.json`, prompts the user, and stores the new APK in the app’s external storage directory before handing off to the system installer.【F:lib/utils/updater.dart†L18-L99】

## Building release artefacts

```bash
# Android APK
flutter build apk --release

# Android App Bundle
flutter build appbundle --release

# Windows Desktop
flutter build windows
```

Adjust the build command for your target platform (see `flutter help build`). Ensure the client configuration includes production API and update endpoints before distributing a release.

## Testing

The repository currently does not contain automated tests. You can add widget, integration or unit tests under the `test/` directory and run them with:

```bash
flutter test
```

## Troubleshooting

- **Cannot find printers** – Confirm that Bluetooth and location permissions are granted on the device and that the printer is powered on.【F:lib/main.dart†L62-L88】【F:lib/bluetooth/bluetoothManager.dart†L49-L132】
- **Stale data after login** – Use the “Refresh” actions exposed by client dashboards; they trigger the `MainController` to reload vehicles, crew and transaction summaries.【F:lib/controllers/main.dart†L45-L77】
- **API requests fail** – Verify the base URL and client identifier in `assets/config.json`, and ensure the backend is reachable from the device’s network.【F:assets/config.json†L1-L18】【F:lib/network/Apis.dart†L25-L63】

## Contributing

1. Fork the repository and create a feature branch.
2. Follow the existing folder conventions (`lib/controllers`, `lib/models`, `lib/pages`, etc.).
3. Run `flutter analyze` (and `flutter test` if tests are added) before submitting a pull request.
4. Describe any configuration changes required for the reviewer in the PR body.

## License

This project is proprietary to the Matatu team. Contact the maintainers for licensing or redistribution enquiries.
