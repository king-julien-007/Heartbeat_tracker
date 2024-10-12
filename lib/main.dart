import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'dart:math' as math;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cameras = await availableCameras();
  runApp(MyApp(cameras: cameras));
}

class MyApp extends StatelessWidget {
  final List<CameraDescription> cameras;

  const MyApp({super.key, required this.cameras});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: HeartbeatDetectorScreen(cameras: cameras),
    );
  }
}

// bro you do one thing install jdk 17 and try again me go have lunch and come back.sure.will this work? yes i guess so. ok bro i will try it. sure bro. i will be back in 30 mins. ok bro. take your time. bye. bye bro. nicesu recopilot

class HeartbeatDetectorScreen extends StatefulWidget {
  final List<CameraDescription> cameras;

  const HeartbeatDetectorScreen({super.key, required this.cameras});

  @override
  _HeartbeatDetectorScreenState createState() =>
      _HeartbeatDetectorScreenState();
}

class _HeartbeatDetectorScreenState extends State<HeartbeatDetectorScreen> {
  CameraController? _cameraController;
  FaceDetector? _faceDetector;
  bool _isDetecting = false;
  int _heartRate = 0;
  final List<double> _greenChannelValues = [];
  DateTime _lastProcessingTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _initializeFaceDetector();
  }

  void _initializeCamera() async {
    final frontCamera = widget.cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.front,
    );
    _cameraController = CameraController(
      frontCamera,
      ResolutionPreset.medium,
      enableAudio: false,
    );
    await _cameraController!.initialize();
    if (mounted) setState(() {});
    _startImageStream();
  }

  void _initializeFaceDetector() {
    _faceDetector = GoogleMlKit.vision.faceDetector(
      FaceDetectorOptions(
        enableClassification: false,
        minFaceSize: 0.1,
      ),
    );
  }

  //use your real device to get camera response .how to? should use
  // enable the developer options then usb debugging and then connect your device to your pc. can you wait a sec!yea im up
  //you th

  void _startImageStream() {
    _cameraController!.startImageStream((CameraImage image) {
      if (_isDetecting) return;
      _isDetecting = true;
      _processImage(image);
    });
  }

  void _processImage(CameraImage image) async {
    try {
      final inputImage = InputImage.fromBytes(
        metadata: InputImageMetadata(
            size: Size(
              image.height.toDouble(),
              image.width.toDouble(),
            ),
            rotation: InputImageRotation.rotation0deg,
            format: InputImageFormat.nv21,
            bytesPerRow: image.planes[0].bytesPerRow),
        bytes: _concatenatePlanes(image.planes),
        // inputImageData: InputImageData(
        //   size: Size(image.width.toDouble(), image.height.toDouble()),
        //   imageRotation: InputImageRotation.Rotation_0deg,
        //   inputImageFormat: InputImageFormat.NV21,
        //   planeData: image.planes.map(
        //     (Plane plane) {
        //       return InputImagePlaneMetadata(
        //         bytesPerRow: plane.bytesPerRow,
        //         height: plane.height,
        //         width: plane.width,
        //       );
        //     },
        //   ).toList(),
        // ),
      );

      // Process the image with the face detector
      final faces = await _faceDetector!.processImage(inputImage);

      if (faces.isNotEmpty) {
        final face = faces.first;
        _detectHeartbeat(image, face);
      }
    } catch (e) {
      print('Error processing image: $e');
    }

    _isDetecting = false;
  }

  Uint8List _concatenatePlanes(List<Plane> planes) {
    final WriteBuffer allBytes = WriteBuffer();
    for (Plane plane in planes) {
      allBytes.putUint8List(plane.bytes);
    }
    return allBytes.done().buffer.asUint8List();
  }

  void _detectHeartbeat(CameraImage image, Face face) {
    // Extract the forehead region
    final foreheadRegion = _extractForeheadRegion(image, face);

    // Calculate average green channel value
    final avgGreen = _calculateAverageGreen(foreheadRegion);

    _greenChannelValues.add(avgGreen);

    // Process every second
    if (DateTime.now().difference(_lastProcessingTime).inSeconds >= 1) {
      _processGreenChannelValues();
      _lastProcessingTime = DateTime.now();
    }
  }

  List<int> _extractForeheadRegion(CameraImage image, Face face) {
    final boundingBox = face.boundingBox;
    final foreheadTop = boundingBox.top + boundingBox.height * 0.2;
    final foreheadBottom = boundingBox.top + boundingBox.height * 0.3;
    final foreheadLeft = boundingBox.left + boundingBox.width * 0.3;
    final foreheadRight = boundingBox.right - boundingBox.width * 0.3;

    List<int> foreheadRegion = [];
    for (int y = foreheadTop.toInt(); y < foreheadBottom.toInt(); y++) {
      for (int x = foreheadLeft.toInt(); x < foreheadRight.toInt(); x++) {
        final pixel = y * image.width + x;
        foreheadRegion.add(image.planes[0].bytes[pixel]);
      }
    }
    return foreheadRegion;
  }

  double _calculateAverageGreen(List<int> region) {
    return region.reduce((a, b) => a + b) / region.length;
  }

  void _processGreenChannelValues() {
    if (_greenChannelValues.length < 60) return; // Need at least 60 samples

    // Apply bandpass filter (simplified)
    List<double> filteredValues = _applyBandpassFilter(_greenChannelValues);

    // Perform Fast Fourier Transform
    List<double> fftResult = _performFFT(filteredValues);

    // Find dominant frequency
    double dominantFreq = _findDominantFrequency(fftResult);

    // Calculate heart rate
    int calculatedHeartRate = (dominantFreq * 60).round();

    setState(() {
      _heartRate = calculatedHeartRate;
    });

    _greenChannelValues.clear();
  }

  List<double> _applyBandpassFilter(List<double> values) {
    // Simplified bandpass filter (0.8 Hz to 3 Hz, corresponding to 48-180 BPM)
    List<double> filtered = List.from(values);
    for (int i = 2; i < filtered.length - 2; i++) {
      filtered[i] = (values[i - 2] +
              values[i - 1] +
              values[i] +
              values[i + 1] +
              values[i + 2]) /
          5;
    }
    return filtered;
  }

  List<double> _performFFT(List<double> values) {
    // Placeholder for FFT implementation
    // In a real implementation, you'd use a proper FFT library
    return List.from(values); // Returning original values for now
  }

  double _findDominantFrequency(List<double> fftResult) {
    // Placeholder: find index of maximum value in fftResult
    int maxIndex = fftResult.indexOf(fftResult.reduce(math.max));
    // Convert index to frequency (assuming 1 Hz sampling rate)
    return maxIndex / fftResult.length;
  }

  @override
  Widget build(BuildContext context) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return Container();
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Heartbeat Detector')),
      body: Column(
        children: [
          CameraPreview(_cameraController!),
          Text('Heartrate: $_heartRate BPM',
              style: const TextStyle(fontSize: 24)),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _faceDetector?.close();
    super.dispose();
  }
}

// do you know where is the flutter sdk?