import 'package:flutter/material.dart';
import 'package:tflite/tflite.dart';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:math' as math;

class ObjectDetectionApp extends StatefulWidget {
  @override
  _ObjectDetectionAppState createState() => _ObjectDetectionAppState();
}

class _ObjectDetectionAppState extends State<ObjectDetectionApp> {
  List<dynamic> _recognitions;
  bool _isDetecting = false;

  @override
  void initState() {
    super.initState();
    loadModel();
  }

  loadModel() async {
    await Tflite.loadModel(
      model: 'assets/model.tflite',
      labels: 'assets/labels.txt',
    );
  }

  Future<void> _detectObjects(ui.Image image) async {
    if (_isDetecting) return;

    setState(() {
      _isDetecting = true;
    });

    try {
      List<dynamic> recognitions = await Tflite.detectObjectOnImage(
        path: '', // You can also use `bytes` instead of `path` here.
        imageMean: 0.0,
        imageStd: 255.0,
        threshold: 0.2,
        numResultsPerClass: 1,
      );

      setState(() {
        _recognitions = recognitions;
      });
    } catch (e) {
      print('Error during object detection: $e');
    } finally {
      setState(() {
        _isDetecting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Object Detection App'),
      ),
      body: FutureBuilder(
        future: loadModel(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return CameraWidget(onImageCaptured: _detectObjects);
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }

  @override
  void dispose() {
    Tflite.close();
    super.dispose();
  }
}

class CameraWidget extends StatefulWidget {
  final Function(ui.Image) onImageCaptured;

  const CameraWidget({Key key, @required this.onImageCaptured}) : super(key: key);

  @override
  _CameraWidgetState createState() => _CameraWidgetState();
}

class _CameraWidgetState extends State<CameraWidget> {
  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints.expand(),
      child: CameraPreview(
        onImageCaptured: widget.onImageCaptured,
      ),
    );
  }
}

class CameraPreview extends StatefulWidget {
  final Function(ui.Image) onImageCaptured;

  const CameraPreview({Key key, @required this.onImageCaptured}) : super(key: key);

  @override
  _CameraPreviewState createState() => _CameraPreviewState();
}

class _CameraPreviewState extends State<CameraPreview> {
  CameraController _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  _initializeCamera() async {
    final cameras = await availableCameras();
    final CameraDescription camera = cameras.first;

    _controller = CameraController(
      camera,
      ResolutionPreset.medium,
    );

    await _controller.initialize();

    if (!mounted) {
      return;
    }

    setState(() {
      _isInitialized = true;
    });

    _startStreaming();
  }

  _startStreaming() {
    _controller.startImageStream((CameraImage image) {
      if (_isInitialized) {
        widget.onImageCaptured(_convertYUV420toImage(image));
      }
    });
  }

  ui.Image _convertYUV420toImage(CameraImage image) {
    // Convert the YUV420 image to a RGBA image.
    // You may need to adjust this conversion based on the format of your model's input.

    final int width = image.width;
    final int height = image.height;

    final Uint8List planeY = image.planes[0].bytes;
    final Uint8List planeU = image.planes[1].bytes;
    final Uint8List planeV = image.planes[2].bytes;

    final int uvRowStride = image.planes[1].bytesPerRow;
    final int uvPixelStride = image.planes[1].bytesPerPixel;

    // Create a buffer for the YUV data
    final Uint8List yuvBytes = Uint8List(image.width * image.height * 3 / 2);

    int i = 0;

    // Fill Y channel
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        yuvBytes[i++] = planeY[y * width + x];
      }
    }

    // Fill U and V channels
    for (int y = 0; y < height / 2; y++) {
      for (int x = 0; x < width / 2; x++) {
        yuvBytes[i++] = planeU[y * uvRowStride + x * uvPixelStride];
        yuvBytes[i++] = planeV[y * uvRowStride + x * uvPixelStride];
      }
    }

    // Create an image from the YUV data
    final Completer<ui.Image> completer = Completer();
    ui.decodeImageFromPixels(
      yuvBytes.buffer.asUint8List(),
      width,
      height,
      ui.PixelFormat.format420f,
          (ui.Image image) => completer.complete(image),
    );

    return completer.future;
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Container();
    }

    return AspectRatio(
      aspectRatio: _controller.value.aspectRatio,
      child: CameraPreview(_controller),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}