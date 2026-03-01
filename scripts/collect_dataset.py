#!/usr/bin/env python3
"""
Dataset Collection Script for Gesture-Based Robotic Arm
Captures images from camera and saves them for training
"""

import cv2
import numpy as np
import os
import sys
from datetime import datetime

class GestureDatasetCollector:
    def __init__(self, dataset_dir="datasets/finger_count"):
        self.dataset_dir = dataset_dir
        self.img_width = 640
        self.img_height = 480
        self.gesture_classes = {
            0: "0_finger",
            1: "1_finger", 
            2: "2_fingers",
            3: "3_fingers",
            4: "4_fingers",
            5: "5_fingers"
        }
        
        # Create directories
        for gesture_id, gesture_name in self.gesture_classes.items():
            os.makedirs(os.path.join(dataset_dir, gesture_name), exist_ok=True)
    
    def preprocess_image(self, frame):
        """Convert image to grayscale (matching FPGA processing)"""
        # Resize if needed
        if frame.shape[:2] != (self.img_height, self.img_width):
            frame = cv2.resize(frame, (self.img_width, self.img_height))
        
        # Convert to grayscale
        gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
        return gray
    
    def get_next_sample_number(self, gesture_id):
        """Get next available sample number for a gesture class"""
        gesture_name = self.gesture_classes[gesture_id]
        gesture_dir = os.path.join(self.dataset_dir, gesture_name)
        
        existing_files = [f for f in os.listdir(gesture_dir) if f.endswith('.raw')]
        if not existing_files:
            return 1
        
        # Extract numbers from filenames
        numbers = []
        for f in existing_files:
            try:
                num = int(f.split('_')[1].split('.')[0])
                numbers.append(num)
            except:
                pass
        
        return max(numbers) + 1 if numbers else 1
    
    def save_sample(self, image, gesture_id):
        """Save image as raw binary file"""
        gesture_name = self.gesture_classes[gesture_id]
        gesture_dir = os.path.join(self.dataset_dir, gesture_name)
        
        sample_num = self.get_next_sample_number(gesture_id)
        filename = f"sample_{sample_num:03d}.raw"
        filepath = os.path.join(gesture_dir, filename)
        
        # Save as raw binary
        image.tofile(filepath)
        
        # Also save as PNG for preview
        png_filename = f"sample_{sample_num:03d}.png"
        png_filepath = os.path.join(gesture_dir, png_filename)
        cv2.imwrite(png_filepath, image)
        
        print(f"✓ Saved: {filepath}")
        return filepath
    
    def run_interactive(self):
        """Interactive dataset collection mode"""
        print("=" * 60)
        print("Gesture Dataset Collection Tool")
        print("=" * 60)
        print("\nControls:")
        print("  0-5: Select gesture class (number of fingers)")
        print("  SPACE: Capture and save current frame")
        print("  'p': Preview mode (toggle preprocessing)")
        print("  'q': Quit")
        print("\nStarting camera...")
        
        # Open camera
        cap = cv2.VideoCapture(0)
        if not cap.isOpened():
            print("Error: Could not open camera")
            return
        
        # Set resolution
        cap.set(cv2.CAP_PROP_FRAME_WIDTH, self.img_width)
        cap.set(cv2.CAP_PROP_FRAME_HEIGHT, self.img_height)
        
        current_gesture = 0
        preview_mode = False
        
        print("\nCamera ready! Current gesture class: 0 fingers")
        
        while True:
            ret, frame = cap.read()
            if not ret:
                print("Error: Failed to capture frame")
                break
            
            # Process frame
            if preview_mode:
                display = self.preprocess_image(frame)
                display = cv2.cvtColor(display, cv2.COLOR_GRAY2BGR)
            else:
                display = frame.copy()
            
            # Add UI overlay
            gesture_name = self.gesture_classes[current_gesture]
            sample_count = len([f for f in os.listdir(os.path.join(self.dataset_dir, gesture_name)) 
                               if f.endswith('.raw')])
            
            cv2.putText(display, f"Gesture: {gesture_name}", (10, 30),
                       cv2.FONT_HERSHEY_SIMPLEX, 0.7, (0, 255, 0), 2)
            cv2.putText(display, f"Samples: {sample_count}", (10, 60),
                       cv2.FONT_HERSHEY_SIMPLEX, 0.7, (0, 255, 0), 2)
            cv2.putText(display, "SPACE: Capture | 0-5: Class | P: Preview | Q: Quit", 
                       (10, self.img_height - 10),
                       cv2.FONT_HERSHEY_SIMPLEX, 0.5, (255, 255, 255), 1)
            
            if preview_mode:
                cv2.putText(display, "PREVIEW MODE", (self.img_width - 200, 30),
                           cv2.FONT_HERSHEY_SIMPLEX, 0.7, (0, 255, 255), 2)
            
            cv2.imshow('Gesture Dataset Collector', display)
            
            key = cv2.waitKey(1) & 0xFF
            
            # Handle key presses
            if key == ord('q'):
                print("\nQuitting...")
                break
            elif key == ord('p'):
                preview_mode = not preview_mode
                print(f"Preview mode: {'ON' if preview_mode else 'OFF'}")
            elif key == ord(' '):
                # Capture and save
                gray = self.preprocess_image(frame)
                self.save_sample(gray, current_gesture)
            elif ord('0') <= key <= ord('5'):
                # Change gesture class
                current_gesture = key - ord('0')
                gesture_name = self.gesture_classes[current_gesture]
                print(f"Selected gesture class: {gesture_name}")
        
        # Cleanup
        cap.release()
        cv2.destroyAllWindows()
        
        # Print summary
        print("\n" + "=" * 60)
        print("Collection Summary:")
        print("=" * 60)
        total_samples = 0
        for gesture_id, gesture_name in self.gesture_classes.items():
            gesture_dir = os.path.join(self.dataset_dir, gesture_name)
            count = len([f for f in os.listdir(gesture_dir) if f.endswith('.raw')])
            print(f"{gesture_name:15s}: {count:3d} samples")
            total_samples += count
        print("-" * 60)
        print(f"{'Total':15s}: {total_samples:3d} samples")
        print("=" * 60)

def main():
    collector = GestureDatasetCollector()
    
    if len(sys.argv) > 1 and sys.argv[1] == "--help":
        print("Usage: python3 collect_dataset.py [dataset_dir]")
        print("\nInteractive gesture dataset collection tool.")
        print("Default dataset directory: datasets/finger_count")
        return
    
    collector.run_interactive()

if __name__ == "__main__":
    main()
