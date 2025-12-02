# NOTAM Parsing with Foundation Models

This app uses Apple's Foundation Models framework to parse NOTAMs (Notices to Air Missions) and extract runway performance data. The on-device language model uses a custom-trained LoRA adapter for accurate extraction.

## Architecture

- **NOTAMAdapterManager** - Downloads and manages the adapter via Background Assets
- **NOTAMParser** - Uses the adapter with `SystemLanguageModel` for structured extraction
- **NOTAMExtraction** - `@Generable` schema defining the extracted data structure

## Adapter Versioning

Adapters are tied to specific Foundation Model toolkit versions, not iOS versions. The system model signature must match between the adapter and device.

| Toolkit Version | Asset Pack ID | Compatible OS |
|-----------------|---------------|---------------|
| 26.0.0 | `notam-adapter-26_0_0` | iOS 26.0+ |

When Apple releases new toolkit versions, train and upload a new adapter, then add the version to `HostedAdapterLoader.toolkitVersions`.

## Development & Testing

### Simulator

Foundation Models adapters are **not supported in the iOS Simulator**. The adapter manager will report "NOTAM adapter not supported on this platform" and NOTAM parsing will be disabled.

To test NOTAM-related UI in the simulator, the app gracefully handles missing adapters - NOTAMs will display but won't be auto-parsed.

### On-Device Debug Builds

For faster iteration during development, you can bundle the adapter directly in the app:

1. **Obtain the adapter** from the training repository:
   ```
   SF50-TOLD Model Training/exports/NOTAMAdapter.fmadapter
   ```

2. **Copy to the Debug resources folder**:
   ```
   SF50 TOLD/Resources/Debug/NOTAMAdapter.fmadapter
   ```

3. **Build and run** - The `BundledAdapterLoader` will automatically use this adapter in `DEBUG` builds on physical devices.

The adapter file (~130MB) is gitignored. The build script tolerates its absence.

### TestFlight / Production

Production builds use Apple-Hosted Background Assets:

1. **Train the adapter** using Apple's adapter training toolkit
2. **Upload to App Store Connect**:
   ```bash
   cd "SF50-TOLD Model Training"
   ./upload_adapter.sh
   ```
3. **Submit for review** in App Store Connect (Asset Packs section)
4. The adapter downloads automatically when users install/update the app

## Training a New Adapter

When Apple releases a new toolkit version:

1. Download the new toolkit from Apple Developer
2. Update training data if needed
3. Train:
   ```bash
   ./train_adapter.sh
   ```
4. Upload:
   ```bash
   ./upload_adapter.sh
   ```
5. Add the new version to `HostedAdapterLoader.toolkitVersions` in Swift

## Entitlements

Production adapter usage requires the **Foundation Models Framework Adapter Entitlement** from Apple. Request it at [developer.apple.com](https://developer.apple.com/apple-intelligence/foundation-models-adapter/).

## Troubleshooting

### "Adapter assets are invalid"
The adapter's `baseModelSignature` doesn't match the device's system model. Ensure you're using an adapter trained with the correct toolkit version for your OS.

### "No asset pack with ID found"
The adapter hasn't been uploaded to App Store Connect, or the build isn't from TestFlight. Direct Xcode installs cannot access Background Assets - use a bundled adapter for local testing.

### Adapter not loading in DEBUG
Ensure the `.fmadapter` bundle is in `SF50 TOLD/Resources/Debug/` and the build phase "Copy FoundationModel Adapter" is present.
