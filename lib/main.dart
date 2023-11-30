import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  File? _imageFile;

  Future<void> _takePicture() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.camera);

    if (image != null) {
      setState(() {
        _imageFile = File(image.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Home'),
        centerTitle: true,
        backgroundColor: Colors.black,
      ),
      bottomNavigationBar: BottomAppBar(
        color: Colors.black26,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            IconButton(
              icon: const Icon(Icons.history, size: 35),
              onPressed: () {},
              color: Colors.white,
            ),
            IconButton(
              icon: const Icon(Icons.settings, size: 35),
              onPressed: () {},
              color: Colors.white,
            ),
          ],
        ),
      ),
      body: Center(
        widthFactor: 2.0,
        heightFactor: 1.2,
        child: _imageFile != null
            ? _ZoomableImage(imageFile: _imageFile!)
            : const Text(''),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _takePicture,
        backgroundColor: Colors.black,
        elevation: 10.0,
        child: const Icon(Icons.camera_alt, size: 36),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}

class _ZoomableImage extends StatefulWidget {
  final File imageFile;

  const _ZoomableImage({Key? key, required this.imageFile}) : super(key: key);

  @override
  __ZoomableImageState createState() => __ZoomableImageState();
}

class __ZoomableImageState extends State<_ZoomableImage> {
  bool _isZoomed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isZoomed = !_isZoomed;
        });
      },
      child: Container(
        child: SizedBox(
          width: _isZoomed ? null : 350.0,
          height: _isZoomed ? null : 350.0,
          child: Image.file(widget.imageFile),
        ),
      ),
    );
  }
}