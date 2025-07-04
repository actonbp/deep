# CloudKit Setup Guide for Bryan's Brain

## Prerequisites

- **Apple Developer Program membership** ($99/year) - Required for CloudKit
- Xcode with your paid developer team selected (not "Personal Team")
- Devices signed into iCloud for testing

## Important Note

CloudKit is **not available** with free Apple Developer accounts. You must have a paid Apple Developer Program membership to use CloudKit sync features.

Follow these steps to enable CloudKit sync in your Xcode project:

## 0. Configure Entitlements (IMPORTANT - Do This First!)

1. An entitlements file has been created at `deep_app/deep_app.entitlements`
2. In Xcode, select your project in the navigator
3. Select the `deep_app` target
4. Go to the **Build Settings** tab
5. Search for "Code Signing Entitlements"
6. Set the value to `deep_app/deep_app.entitlements`

Alternatively, in the **Signing & Capabilities** tab:
- The entitlements file should be automatically detected
- If not, you may need to remove and re-add the CloudKit capability

## 1. Enable CloudKit Capability

1. Open your project in Xcode
2. Select the `deep_app` target
3. Go to the **Signing & Capabilities** tab
4. Click the **+ Capability** button
5. Search for and add **CloudKit**

## 2. Configure CloudKit Container

1. In the CloudKit capability section, you'll see a CloudKit container
2. It should automatically create one named: `iCloud.com.bryanacton.deep`
3. If not, click the **+** button to create a new container with this identifier

## 3. Create CloudKit Schema (Optional - Auto-created on first use)

The app will automatically create the necessary CloudKit schema when it first runs, but you can also set it up manually:

1. Go to [CloudKit Dashboard](https://icloud.developer.apple.com/)
2. Sign in with your Apple Developer account
3. Select your container: `iCloud.com.bryanacton.deep`
4. Go to **Schema** → **Record Types**
5. Create a new record type called `TodoItem` with these fields:
   - `text` (String)
   - `isDone` (Int64)
   - `priority` (Int64)
   - `estimatedDuration` (String)
   - `category` (String)
   - `projectOrPath` (String)
   - `difficulty` (String)
   - `createdAt` (Date/Time)

## 4. Test CloudKit Integration

1. Build and run the app on a device or simulator signed into iCloud
2. Add some tasks in the app
3. Check the CloudKit Dashboard to verify records are being created
4. Install the app on another device with the same iCloud account
5. Verify that tasks sync between devices

## 5. Important Notes

- **iCloud Account Required**: Users must be signed into iCloud for sync to work
- **Network Connection**: Initial sync requires an internet connection
- **Privacy**: All data stays in the user's private iCloud container
- **Free Tier**: CloudKit provides 1GB free storage per user

## 6. Troubleshooting

If sync isn't working:

1. **Check iCloud Status**: Ensure the device is signed into iCloud
2. **Check Console Logs**: Look for messages starting with "☁️" 
3. **Verify Capability**: Ensure CloudKit is enabled in Signing & Capabilities
4. **Container Name**: Verify the container ID matches exactly
5. **Network**: Ensure the device has an internet connection

## 7. Testing in Development

For development testing:
- Use different simulators with the same iCloud account
- Or use your iPhone and iPad with the same account
- Changes should sync within a few seconds

## Current Implementation Status

✅ **Implemented:**
- CloudKitManager with full CRUD operations
- Integration with TodoListStore
- Automatic sync on app launch
- **Auto-sync on app lifecycle (foreground/background)**
- Save new items to CloudKit
- Delete sync for all deletion methods
- Update sync for task completion status
- Update sync for task metadata (category, project/path, difficulty)
- Update sync for task priorities (manual reordering)
- Update sync for task duration estimates
- CloudKit subscription for change notifications
- **Visual sync status indicators in UI**
- **Manual refresh button for force sync**
- **Smart error handling for duplicate saves**
- **Automatic schema creation on first run**
- **Fallback query methods for compatibility**

⏳ **TODO (Future Improvements):**
- Real-time sync (currently requires app relaunch to see changes from other devices)
- Conflict resolution for simultaneous edits
- Offline queue for changes made without internet
- Notes/Scratchpad sync 
- Progress indicator during initial sync
- Batch operations for better performance
- Pull-to-refresh gesture
- Last sync timestamp display 