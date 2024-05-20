import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:tflite/tflite.dart';

class DeteksiPenyakitPage extends StatefulWidget {
  const DeteksiPenyakitPage({Key? key}) : super(key: key);

  @override
  _DeteksiPenyakitPageState createState() => _DeteksiPenyakitPageState();
}

class _DeteksiPenyakitPageState extends State<DeteksiPenyakitPage> {
  late CameraController _camController;
  String? pathDir;
  bool _showCamera = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    initCameraAndModel();
  }

  Future<void> initCameraAndModel() async {
    WidgetsFlutterBinding.ensureInitialized();
    try {
      final cameras = await availableCameras();
      log("Available cameras: ${cameras.length}");
      _camController = CameraController(cameras[0], ResolutionPreset.high);
      await _camController.initialize();
      log("Camera initialized");
      
      await Tflite.loadModel(
        model: 'assets/mymodel/model.tflite',
        labels: 'assets/mymodel/labels.txt',
      );
      log("Model loaded successfully");
    } catch (e) {
      log("Error during camera or model initialization: ${e.toString()}");
    } finally {
      setState(() {
        _isLoading = false;
      });
      log("TFLite model loaded");
    }
  }

  Future<String?> takePicture() async {
    try {
      if (!_camController.value.isTakingPicture) {
        XFile? img = await _camController.takePicture();
        log("Picture taken at: ${img.path}");
        return img.path;
      }
    } catch (e) {
      log("Error taking picture: ${e.toString()}");
    }
    return null;
  }

  Future<dynamic> predict(String path) async {
    try {
      log("Running prediction on image: $path");
      var prediksi = await Tflite.runModelOnImage(
        path: path,
        imageMean: 0.0,
        imageStd: 255.0,
        numResults: 3,
        threshold: 0.2,
        asynch: true,
      );
      log("Prediction result: $prediksi");
      return prediksi;
    } catch (e) {
      log("Error during prediction: ${e.toString()}");
    }
    return null;
  }

  @override
  void dispose() {
    _camController.dispose();
    Tflite.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          _showCamera ? _buildCameraView() : _buildWelcomeScreen(),
          if (_isLoading)
            Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }

  Widget _buildCameraView() {
    return Column(
      children: [
        Expanded(
          child: _camController.value.isInitialized
              ? CameraPreview(_camController)
              : Center(child: Text('Loading Camera...')),
        ),
        Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              FloatingActionButton(
                onPressed: () {
                  setState(() {
                    _showCamera = false;
                  });
                },
                child: Icon(Icons.close),
                backgroundColor: Colors.red,
              ),
              FloatingActionButton(
                onPressed: () async {
                  if (!_camController.value.isTakingPicture) {
                    pathDir = await takePicture();
                    if (pathDir != null) {
                      log("Picture path: $pathDir");
                      var prediction = await predict(pathDir!);
                      showModalBottomSheet(
                        context: context,
                        builder: (context) {
                          return FutureBuilder(
                            future: predict(pathDir!),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.done) {
                                if (snapshot.hasData && snapshot.data != null) {
                                  var predictionData = snapshot.data as List<dynamic>;
                                  if (predictionData.isEmpty) {
                                    return Center(
                                      child: Text(
                                        "Tidak ada hasil prediksi.",
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    );
                                  }
                                  String label = predictionData[0]['label'];
                                  double confidence = predictionData[0]['confidence'];

                                  return Container(
                                    padding: EdgeInsets.all(20),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Hasil Pengecekan:",
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        SizedBox(height: 20),
                                        Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Container(
                                              width: 60,
                                              height: 60,
                                              decoration: BoxDecoration(
                                                color: Colors.grey[200],
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                            ),
                                            SizedBox(width: 20),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    label,
                                                    style: TextStyle(
                                                      fontSize: 18,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                  SizedBox(height: 5),
                                                  Text(
                                                    "Confidence: ${confidence.toStringAsFixed(2)}",
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      color: Colors.grey[700],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 20),
                                        Text(
                                          "Informasi Tambahan:",
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        SizedBox(height: 10),
                                        Text(
                                          "Cabai adalah tumbuhan penghasil buah yang digunakan sebagai bumbu masakan atau sebagai sumber rasa pedas. Buah cabai dapat memiliki berbagai warna, mulai dari merah, hijau, hingga kuning, tergantung pada varietasnya.",
                                          style: TextStyle(
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                } else {
                                  return Center(
                                    child: Text(
                                      "Tidak ada data prediksi.",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  );
                                }
                              } else {
                                return Center(
                                  child: CircularProgressIndicator(),
                                );
                              }
                            },
                          );
                        },
                      );
                    } else {
                      log("Error: Picture path is null");
                    }
                  }
                },
                child: Icon(Icons.camera),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWelcomeScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "Selamat datang di Deteksi Penyakit!",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _showCamera = true;
              });
            },
            child: Text('Mulai Deteksi'),
          ),
        ],
      ),
    );
  }

  Widget _buildScanButton() {
    return ElevatedButton(
      onPressed: () {
        setState(() {
          _showCamera = true;
        });
      },
      child: Text('Scan'),
    );
  }
}
