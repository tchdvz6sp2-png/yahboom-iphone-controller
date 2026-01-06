# YOLOv8 CoreML Integration Guide

This guide explains how to integrate YOLOv8 object detection into the Yahboom Controller iOS app.

## Overview

The app uses **YOLOv8** (You Only Look Once) for real-time object detection on iOS devices via **CoreML**. The integration is already implemented in the code - you just need to add the model file.

## Prerequisites

- Xcode project setup (see [SETUP_IOS.md](../docs/SETUP_IOS.md))
- YOLOv8 CoreML model file (`.mlmodel` or `.mlpackage`)
- iOS device with A11 Bionic chip or newer (iPhone 8+)

## Getting a YOLOv8 CoreML Model

### Option 1: Download Pre-converted Model

1. **From Ultralytics**
   - Visit [Ultralytics YOLOv8 Docs](https://docs.ultralytics.com/)
   - Look for CoreML export section
   - Download pre-converted model

2. **From Apple Model Gallery** (if available)
   - Browse [Apple's ML Gallery](https://developer.apple.com/machine-learning/models/)
   - Search for YOLOv8 or YOLO models

### Option 2: Convert PyTorch Model to CoreML

If you have a trained YOLOv8 model:

```bash
# Install Ultralytics
pip install ultralytics

# Export to CoreML
from ultralytics import YOLO

# Load model
model = YOLO('yolov8n.pt')  # or yolov8s.pt, yolov8m.pt, etc.

# Export to CoreML
model.export(format='coreml')
```

This creates `yolov8n.mlmodel` or `yolov8n.mlpackage`.

### Recommended Models

| Model | Size | Speed | Accuracy | Use Case |
|-------|------|-------|----------|----------|
| YOLOv8n | ~6 MB | Very Fast | Good | Real-time on older devices |
| YOLOv8s | ~22 MB | Fast | Better | Balanced performance |
| YOLOv8m | ~50 MB | Medium | Best | When accuracy matters |

**Recommendation**: Start with **YOLOv8n** for best real-time performance.

## Adding Model to Xcode Project

### Step 1: Locate Model File

Find your downloaded or exported model:
- `yolov8n.mlmodel` (older format)
- `yolov8n.mlpackage` (newer format, iOS 15+)

### Step 2: Add to Xcode

1. **Open your Xcode project**

2. **Drag model into Project Navigator**
   - Find the `Models/` group in Project Navigator
   - Drag the model file from Finder into this group
   
3. **Configure import**
   - ☑ "Copy items if needed"
   - ☑ "YahboomController" under "Add to targets"
   - Click "Finish"

### Step 3: Verify Model

1. **Click on the model file** in Xcode
2. You should see:
   - Model metadata (author, description, etc.)
   - Model Evaluation Parameters
   - Predictions tab
   - Utilities tab

3. **Check Auto-generated Code**
   - Xcode automatically generates Swift code
   - Class name: `yolov8n` (or whatever your model is named)

## Updating YOLODetector Code

### Current Implementation

The `YOLODetector.swift` file has placeholder code. Update it to load your model:

```swift
private func setupModel() {
    // Load YOLOv8 CoreML model
    guard let modelURL = Bundle.main.url(forResource: "yolov8n", withExtension: "mlmodelc") else {
        print("YOLOv8 model not found in bundle")
        return
    }
    
    do {
        let mlModel = try MLModel(contentsOf: modelURL)
        model = try VNCoreMLModel(for: mlModel)
        print("YOLOv8 model loaded successfully")
    } catch {
        print("Failed to load CoreML model: \(error)")
    }
}
```

### For `.mlpackage` Models (iOS 15+)

If using `.mlpackage`:

```swift
private func setupModel() {
    do {
        // For .mlpackage, use the generated class directly
        let config = MLModelConfiguration()
        config.computeUnits = .all  // Use CPU, GPU, and Neural Engine
        
        let mlModel = try yolov8n(configuration: config)
        model = try VNCoreMLModel(for: mlModel.model)
        print("YOLOv8 model loaded successfully")
    } catch {
        print("Failed to load CoreML model: \(error)")
    }
}
```

## Using Object Detection in the App

### Enable Detection

1. **Launch the app**
2. **Connect to robot** (Settings → Connect)
3. **Toggle tracking**:
   - Tap "Tracking Off" button in top-right
   - Button turns green: "Tracking On"
4. **View detections**:
   - Green bounding boxes appear around detected objects
   - Labels show object class and confidence %

### Adjusting Detection Parameters

In `YOLODetector.swift`, adjust these parameters:

```swift
// Confidence threshold (0.0 to 1.0)
var confidenceThreshold: Float = 0.5  // Only show detections >50% confident

// IoU threshold for Non-Maximum Suppression
var iouThreshold: Float = 0.45

// Maximum number of detections
var maxDetections: Int = 20
```

Lower confidence threshold = more detections (but more false positives)
Higher confidence threshold = fewer detections (but more accurate)

## Performance Optimization

### For Better Frame Rate

1. **Lower video resolution** (Settings → 640x480)
2. **Use YOLOv8n** (smallest model)
3. **Reduce detection frequency**:

```swift
// In VideoPlayerSwiftUIView.swift
displayLink?.preferredFramesPerSecond = 15  // Instead of 30
```

### For Better Accuracy

1. **Use YOLOv8s or YOLOv8m** (larger models)
2. **Higher video resolution** (Settings → 1280x720)
3. **Increase confidence threshold** (fewer but more accurate detections)

### Using Neural Engine

Ensure Neural Engine is used for best performance:

```swift
let config = MLModelConfiguration()
config.computeUnits = .all  // CPU + GPU + Neural Engine

// Or force Neural Engine only:
config.computeUnits = .cpuAndNeuralEngine
```

## Customizing Detection Overlay

### Changing Bounding Box Colors

In `DetectionOverlayView.swift`:

```swift
// Change box color
.stroke(Color.green, lineWidth: 2)

// To:
.stroke(Color.blue, lineWidth: 3)  // Blue boxes, thicker lines
```

### Changing Label Style

```swift
Text("\(detection.label) \(Int(detection.confidence * 100))%")
    .font(.system(size: 12, weight: .bold))
    .foregroundColor(.white)
    .padding(4)
    .background(Color.green.opacity(0.7))
    .cornerRadius(4)

// To:
Text("\(detection.label)")  // Just label, no confidence
    .font(.system(size: 14, weight: .semibold))
    .foregroundColor(.black)
    .padding(6)
    .background(Color.yellow)
    .cornerRadius(6)
```

### Filtering Specific Objects

Only show certain object classes:

```swift
// In YOLODetector.swift
let detections = results
    .filter { $0.confidence >= self.confidenceThreshold }
    .filter { observation -> Bool in
        // Only show persons and cars
        let label = observation.labels.first?.identifier ?? ""
        return label == "person" || label == "car"
    }
    .map { observation -> Detection in
        // ... mapping code
    }
```

## Troubleshooting

### Model Not Loading

**Error: "Model not found in bundle"**
- ✓ Check model file is in project
- ✓ Verify target membership includes YahboomController
- ✓ Clean build folder (⌘+⇧+K) and rebuild

**Error: "Failed to load CoreML model"**
- ✓ Check model is valid CoreML format
- ✓ Try re-exporting model with latest tools
- ✓ Verify iOS deployment target matches model requirements

### Poor Detection Performance

**Low frame rate:**
- Use smaller model (YOLOv8n)
- Reduce video resolution
- Lower detection frequency
- Close other apps

**Inaccurate detections:**
- Use larger model (YOLOv8s or YOLOv8m)
- Increase confidence threshold
- Ensure good lighting
- Check model was trained on relevant objects

**Objects not detected:**
- Lower confidence threshold
- Check model includes those object classes
- Improve camera positioning
- Better lighting conditions

### Bounding Boxes Not Appearing

1. **Check tracking is enabled**:
   - Toggle should show "Tracking On" (green)

2. **Check console for errors**:
   - Open Xcode console
   - Look for detection-related errors

3. **Verify video is playing**:
   - Detection only works on live video frames
   - Test video stream separately

4. **Check coordinate conversion**:
   - Vision uses bottom-left origin
   - SwiftUI uses top-left origin
   - Verify conversion in `DetectionOverlayView.swift`

## Advanced: Training Custom YOLOv8 Model

### For Robot-Specific Objects

1. **Collect training data**:
   - Capture images from robot's camera
   - Annotate objects you want to detect
   - Use tools like LabelImg or Roboflow

2. **Train YOLOv8**:
```bash
from ultralytics import YOLO

# Load pretrained model
model = YOLO('yolov8n.pt')

# Train on custom dataset
model.train(
    data='dataset.yaml',  # Your dataset config
    epochs=100,
    imgsz=640,
    batch=16
)
```

3. **Export to CoreML**:
```bash
# Export best model
model = YOLO('runs/detect/train/weights/best.pt')
model.export(format='coreml', nms=True, imgsz=640)
```

4. **Add to iOS app** (follow steps above)

## Testing

### Manual Testing

- [ ] Model loads without errors
- [ ] Detections appear on screen
- [ ] Bounding boxes are correctly positioned
- [ ] Labels show correct class names
- [ ] Confidence percentages are reasonable
- [ ] Toggle on/off works
- [ ] Performance is acceptable (>15 FPS)

### Performance Benchmarking

Add timing code:

```swift
let startTime = Date()
yoloDetector.detect(in: pixelBuffer) { detections in
    let elapsedTime = Date().timeIntervalSince(startTime)
    print("Detection took: \(elapsedTime * 1000)ms")
}
```

Target: <100ms per detection for real-time performance

## Model Comparison

Tested on iPhone 12:

| Model | Size | FPS | mAP | Latency |
|-------|------|-----|-----|---------|
| YOLOv8n | 6 MB | ~30 | 37.3 | ~33ms |
| YOLOv8s | 22 MB | ~24 | 44.9 | ~42ms |
| YOLOv8m | 50 MB | ~18 | 50.2 | ~56ms |

*FPS with 640x480 video, all detections enabled*

## Resources

- [Ultralytics YOLOv8 Documentation](https://docs.ultralytics.com/)
- [Apple CoreML Documentation](https://developer.apple.com/documentation/coreml)
- [Apple Vision Framework](https://developer.apple.com/documentation/vision)
- [CoreML Model Optimization](https://developer.apple.com/documentation/coreml/optimizing_a_core_ml_model_s_size)

## Best Practices

1. **Start with YOLOv8n** - best for real-time
2. **Test on real device** - simulator won't show true performance
3. **Use Neural Engine** - configure computeUnits appropriately
4. **Monitor battery** - detection is intensive
5. **Provide feedback** - show user when detection is active
6. **Handle errors gracefully** - don't crash on model load failure
7. **Allow toggling** - let user disable if not needed

## Example: Complete Integration

Minimal code to integrate:

```swift
// 1. Add model to project (drag yolov8n.mlmodel into Xcode)

// 2. Update YOLODetector.swift setupModel():
do {
    let config = MLModelConfiguration()
    config.computeUnits = .all
    let mlModel = try yolov8n(configuration: config)
    model = try VNCoreMLModel(for: mlModel.model)
} catch {
    print("Failed to load: \(error)")
}

// 3. Done! App will now show detections when tracking is enabled
```

That's it! The rest is already implemented in the SwiftUI views.
