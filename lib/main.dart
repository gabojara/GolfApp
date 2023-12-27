// ignore_for_file: library_private_types_in_public_api, depend_on_referenced_packages, avoid_print

import 'dart:io';
import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
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
  String? _type;

  Future<void> _takePicture(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: source);

    if (image != null) {
      final bool isGolfClubImage = await sendImageToApi(File(image.path));
      if (isGolfClubImage) {
        setState(() {
          _imageFile = File(image.path);
        });
      } else {
        _showNoGolfClubMessage();
      }
    }
  }

  Future<bool> sendImageToApi(File imageFile) async {
    const String apiKey = 'acc_12577c734ffffe1';
    const String apiSecret = '36426b125488354ecf04f9cd6b6aeeff';
    final String basicAuth = 'Basic ${base64Encode(utf8.encode('$apiKey:$apiSecret'))}';

    final Uri apiUrl = Uri.parse('https://api.imagga.com/v2/tags');

    final http.Response response = await http.post(
      apiUrl,
      headers: <String, String>{
        'Authorization': basicAuth,
      },
      body: <String, dynamic>{
        'image_base64': base64Encode(await imageFile.readAsBytes()),
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = json.decode(response.body);

      if (responseData.containsKey('result') && responseData['result'].containsKey('tags') && responseData['result']['tags'].isNotEmpty) {
        final List<dynamic> tags = responseData['result']['tags'];
        for (final tag in tags) {
          if (tag['tag']['en'] == 'metal') {
            _type = 'Metal';
            break;
          } else if (tag['tag']['en'] == 'wooden') {
            _type = 'Wooden';
            break;
          } else {
            _type = 'Unknown';
            break;
          }
        }

        for (final tag in tags) {
          if (tag['tag']['en'] == 'golf club' || tag['tag']['en'] == 'golf') {
            return true;
          }
        }
      }
      return false;
    } else {
      print('API request failed. Status code: ${response.statusCode}');
      print('Response: ${response.body}');
      return false;
    }
  }

  void _showNoGolfClubMessage() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('エラーが発生しました！'),
          content: const Text('選択した画像にはゴルフクラブが含まれていません。'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('ホーム'),
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
            const SizedBox(width: 20),
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
            ? _ZoomableImage(imageFile: _imageFile!, type: _type!,)
            : const Text(''),
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FloatingActionButton(
            onPressed: () => _takePicture(ImageSource.camera),
            backgroundColor: Colors.black,
            elevation: 10.0,
            child: const Icon(Icons.camera_alt, size: 36),
          ),
          const SizedBox(width: 16),
          FloatingActionButton(
            onPressed: () => _takePicture(ImageSource.gallery),
            backgroundColor: Colors.black,
            elevation: 10.0,
            child: const Icon(Icons.image, size: 36),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}

class _ZoomableImage extends StatefulWidget {
  final File imageFile;
  final String type;

  const _ZoomableImage({Key? key, required this.imageFile, required this.type}) : super(key: key);

  @override
  __ZoomableImageState createState() => __ZoomableImageState();
}

class __ZoomableImageState extends State<_ZoomableImage> {
  bool _isZoomed = false;

  double _generateRandomNumber(double min, double max) {
    final Random random = Random();
    return min + random.nextDouble() * (max - min);
  }

  @override
  Widget build(BuildContext context) {
    final double grosor = _generateRandomNumber(4.0, 6.0);
    final double ancho = _generateRandomNumber(2.0, 4.0);
    final double largo = _generateRandomNumber(85.0, 110.0);

    return Container(
      margin: const EdgeInsets.only(bottom: 50.0),
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          GestureDetector(
            onTap: () {
              setState(() {
                _isZoomed = !_isZoomed;
              });
            },
            child: SizedBox(
              width: _isZoomed ? null : 400.0,
              height: _isZoomed ? null : 400.0,
              child: Image.file(widget.imageFile),
            ),
          ),
          if (!_isZoomed)
            Positioned(
              bottom: 0,
              child: Container(
                width: MediaQuery.of(context).size.width,
                color: Colors.white,
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      '厚さ: ${grosor.toStringAsFixed(2)} cm',
                      style: const TextStyle(color: Colors.black, fontSize: 20),
                    ),
                    Text(
                      '幅: ${ancho.toStringAsFixed(2)} cm',
                      style: const TextStyle(color: Colors.black, fontSize: 20),
                    ),
                    Text(
                      '長さ: ${largo.toStringAsFixed(2)} cm',
                      style: const TextStyle(color: Colors.black, fontSize: 20),
                    ),
                    Text(
                      '素材の種類: ${widget.type}',
                      style: const TextStyle(color: Colors.black, fontSize: 20),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
