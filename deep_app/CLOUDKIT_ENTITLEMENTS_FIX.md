# CloudKit Entitlements Fix

## The Error
"In order to use CloudKit, your process must have a com.apple.developer.icloud-services entitlement"

## The Solution
I've created an entitlements file at `deep_app/deep_app.entitlements` with the necessary CloudKit permissions.

## Steps to Apply in Xcode:

### Method 1: Automatic (Preferred)
1. Open `deep_app.xcodeproj` in Xcode
2. Select the project in the navigator (top item)
3. Select the `deep_app` target
4. Go to **Signing & Capabilities** tab
5. If CloudKit capability is already there, remove it (click the X)
6. Click **+ Capability** and add CloudKit again
7. Xcode should automatically detect and use the entitlements file

### Method 2: Manual
1. Open `deep_app.xcodeproj` in Xcode
2. Select the project in the navigator
3. Select the `deep_app` target
4. Go to **Build Settings** tab
5. Search for "Code Signing Entitlements"
6. Set the value to: `deep_app/deep_app.entitlements`

### Method 3: If Still Not Working
1. In Xcode, right-click on the `deep_app` folder in the project navigator
2. Select "Add Files to deep_app..."
3. Navigate to and select `deep_app.entitlements`
4. Make sure "Copy items if needed" is unchecked
5. Make sure your target is selected in "Add to targets"
6. Click "Add"

## Verify It's Working
1. Build and run the app
2. Check the console for "☁️ iCloud is available" message
3. The CloudKit error should be gone

## Important Notes
- You must be signed into iCloud on the simulator/device
- You need an active Apple Developer account for CloudKit to work
- The container ID `iCloud.com.bryanacton.deep` must match your app's bundle identifier 