# CloudKit Setup Guide for Bryan's Brain

Follow these steps to enable CloudKit sync in your Xcode project:

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
- CloudKitManager with basic CRUD operations
- Integration with TodoListStore
- Automatic sync on app launch
- Save new items to CloudKit

⏳ **TODO (Future Improvements):**
- Delete sync (currently only adds/updates)
- Conflict resolution for simultaneous edits
- Offline queue for changes made without internet
- Sync status UI indicator
- Notes/Scratchpad sync 