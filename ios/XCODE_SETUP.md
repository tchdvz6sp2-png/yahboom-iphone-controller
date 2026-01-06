# Creating the Xcode Project

Since Xcode project files (.xcodeproj) are complex binary/XML hybrid files that are best created by Xcode itself, follow these steps to create the project:

## Method 1: Create New Project in Xcode (Recommended)

1. **Open Xcode** (version 14.0 or later)

2. **Create New Project**
   - File → New → Project
   - Select "iOS" tab
   - Choose "App" template
   - Click "Next"

3. **Configure Project**
   - Product Name: `YahboomController`
   - Team: Select your development team
   - Organization Identifier: `com.yourname` (or your preferred identifier)
   - Interface: `SwiftUI`
   - Language: `Swift`
   - Storage: `None`
   - Include Tests: (optional)
   - Click "Next"

4. **Choose Location**
   - Navigate to: `yahboom-iphone-controller/ios/`
   - Create folder named `YahboomController` if it doesn't exist
   - Click "Create"

5. **Replace Generated Files**
   - Xcode will generate some default files
   - Delete the auto-generated `ContentView.swift`
   - The files in this repository should replace/supplement the generated structure:
     - Keep the generated `.xcodeproj` file
     - Replace `YahboomControllerApp.swift` with ours
     - Replace `Assets.xcassets` with ours
     - Replace `Info.plist` with ours
     - Add all files from `Models/`, `ViewModels/`, `Views/`, and `Managers/` directories

6. **Add Files to Project**
   - Right-click on the `YahboomController` group in Xcode
   - Select "Add Files to YahboomController..."
   - Select all folders: Models, ViewModels, Views, Managers
   - Ensure "Copy items if needed" is unchecked (files are already in place)
   - Ensure "Create groups" is selected
   - Ensure your target is checked
   - Click "Add"

7. **Configure Build Settings**
   - Select the project in the navigator
   - Select the "YahboomController" target
   - Go to "General" tab:
     - Display Name: `Yahboom Controller`
     - Bundle Identifier: `com.yourname.YahboomController`
     - Version: `1.0.0`
     - Build: `1`
     - Minimum Deployments: `iOS 15.0`
   
8. **Configure Signing & Capabilities**
   - Go to "Signing & Capabilities" tab
   - Select your Team
   - Signing Certificate: Automatic
   
9. **Add Required Capabilities** (if not present)
   - Click "+ Capability"
   - Add "Background Modes" (if needed for background operation)

10. **Build the Project**
    - Select your target device or simulator
    - Press Cmd+B to build
    - Fix any issues that appear

11. **Run the App**
    - Connect your iPhone or select a simulator
    - Press Cmd+R to run
    - Grant any requested permissions

## Method 2: Using Provided Files

All Swift source files are included in this repository. To use them:

1. Follow steps 1-4 above to create the base project
2. Delete all auto-generated Swift files
3. Copy all files from this repository into the project folder:
   ```bash
   cp -r Models ViewModels Views Managers Resources YahboomControllerApp.swift Info.plist [Xcode-Project-Location]/YahboomController/
   ```
4. In Xcode, add the files to the project (File → Add Files to "YahboomController"...)

## Project Structure in Xcode

After adding all files, your Xcode project navigator should look like:

```
YahboomController
├── YahboomControllerApp.swift
├── Models
│   ├── RobotSettings.swift
│   ├── MotorCommand.swift
│   └── PersonDetection.swift
├── ViewModels
│   ├── ConnectionViewModel.swift
│   ├── StreamViewModel.swift
│   ├── ControlViewModel.swift
│   └── TrackingViewModel.swift
├── Views
│   ├── MainView.swift
│   ├── SettingsView.swift
│   ├── StreamView.swift
│   ├── JoystickView.swift
│   └── ConnectionIndicator.swift
├── Managers
│   ├── SSHManager.swift
│   ├── UDPClient.swift
│   ├── RTSPPlayer.swift
│   ├── KeychainManager.swift
│   └── PersonTracker.swift
├── Resources
│   ├── Assets.xcassets
│   │   ├── AppIcon.appiconset
│   │   └── Contents.json
│   └── Info.plist
└── Products
    └── YahboomController.app
```

## Build Settings

### Deployment Info
- iOS Deployment Target: 15.0
- Devices: iPhone
- Supported Orientations: Portrait, Landscape Left, Landscape Right

### Frameworks and Libraries
All frameworks are part of iOS SDK:
- SwiftUI.framework
- AVFoundation.framework
- CoreML.framework
- Vision.framework
- Network.framework
- Security.framework

No external dependencies required.

## Adding YOLOv8 CoreML Model (Optional for Person Tracking)

If you want to enable person tracking:

1. **Export YOLOv8n to CoreML**
   ```python
   from ultralytics import YOLO
   model = YOLO('yolov8n.pt')
   model.export(format='coreml', nms=True)
   ```

2. **Add to Xcode**
   - Drag the generated `.mlmodel` file into Xcode
   - Place it in the Resources folder
   - Ensure "Target Membership" includes YahboomController
   - Xcode will automatically generate Swift wrapper classes

3. **Update PersonTracker.swift**
   - Uncomment the model loading code
   - Update the model name to match your file

Without the CoreML model, the app will still run but person tracking will be disabled.

## Testing

### Simulator
- The app can run in the iOS Simulator
- Network features will work but won't connect to actual robot
- Use for UI testing and development

### Device
- Connect iPhone via USB
- Select device as target
- Build and run (Cmd+R)
- First time: Trust developer in Settings → General → VPN & Device Management

## Common Issues

### "No such module 'SwiftUI'"
- Solution: Ensure iOS Deployment Target is set to iOS 15.0 or later

### Signing Error
- Solution: Select your Team in Signing & Capabilities
- May need to change Bundle Identifier if there's a conflict

### "Could not find included file 'Info.plist'"
- Solution: Ensure Info.plist is in the project and added to target

### Build Errors
- Solution: Clean build folder (Shift+Cmd+K) and rebuild

## Next Steps

After creating the project:
1. Review the code in each file
2. Customize as needed for your robot
3. Test in simulator first
4. Deploy to physical device
5. Configure settings in the app
6. Connect to your Yahboom robot

## Support

For issues:
- Check the main README.md
- Review docs/SETUP_IOS.md
- Examine docs/TROUBLESHOOTING.md
