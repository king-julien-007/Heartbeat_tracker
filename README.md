Heartbeat Detector App

The Heartbeat Detector is a Flutter app that uses the camera and Google's ML Kit Face Detection API to estimate the user's heart rate by analyzing the color changes in the skin on the forehead. The app processes the camera feed in real time, detects the face, and calculates the heart rate using the green channel from the camera's image stream.

Features
Real-time heart rate detection: The front camera detects a face and extracts green channel values for heart rate analysis.
Face detection: Utilizes Google's ML Kit Face Detection API to track the face and focus on the forehead region.
FFT Analysis: The fast Fourier Transform (FFT) is applied to the green channel data to extract the dominant frequency, which corresponds to the heart rate.
Bandpass filter: Filters out noise from the green channel data to ensure accurate heart rate calculation.
