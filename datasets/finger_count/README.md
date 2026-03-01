# Finger Count Dataset for Gesture Recognition

## Dataset Structure

This directory contains sample gesture datasets for training and testing the gesture recognition system.

### Finger Count Gestures (0-5 fingers)

The dataset includes 10-15 samples for each gesture type:

1. **0 Fingers (Fist)**: Closed hand/fist gesture
2. **1 Finger**: Index finger pointing up
3. **2 Fingers**: Peace sign or index + middle fingers
4. **3 Fingers**: Three fingers extended
5. **4 Fingers**: Four fingers extended
6. **5 Fingers**: Open palm with all fingers extended

### Dataset Format

Each sample consists of:
- **Image**: 640x480 grayscale image captured from camera
- **Label**: Finger count (0-5)
- **Metadata**: Lighting conditions, hand orientation, etc.

### Sample Naming Convention

```
finger_count/
├── 0_finger/
│   ├── sample_001.raw
│   ├── sample_002.raw
│   └── ...
├── 1_finger/
│   ├── sample_001.raw
│   ├── sample_002.raw
│   └── ...
├── 2_fingers/
├── 3_fingers/
├── 4_fingers/
└── 5_fingers/
```

### Data Collection

1. Camera captures 640x480 frames at 30 FPS
2. Images are converted to grayscale (8-bit)
3. Each sample is saved as raw binary format (307,200 bytes per image)
4. Samples should include various lighting conditions and hand positions

### Preprocessing

Before feeding to the FPGA:
1. **Normalization**: Adjust brightness/contrast
2. **Thresholding**: Convert to binary image (threshold = 128)
3. **Noise Reduction**: Apply median filter if needed
4. **ROI Detection**: Detect hand region for focused processing

### Usage in FPGA

The gesture recognizer module uses:
- Simple pixel counting for initial prototype
- Can be upgraded to use ML-based classification
- Hardware accelerator integration planned for future enhancement

## Future Enhancements

When implementing ML hardware accelerator:
1. Expand dataset to 1000+ samples per gesture
2. Add more gesture types (thumbs up, OK sign, etc.)
3. Include hand tracking and motion gestures
4. Implement CNN-based classification in hardware
