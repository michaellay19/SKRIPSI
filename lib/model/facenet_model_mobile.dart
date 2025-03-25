import 'dart:io';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

class FaceNetModel {
  late Interpreter _interpreter;
  late List<int> _inputShape;
  late List<int> _outputShape;

  FaceNetModel() {
    _loadModel();
  }

  Future<void> _loadModel() async {
    _interpreter = await Interpreter.fromAsset('assets/facenet_model(11).tflite');
    _inputShape = _interpreter.getInputTensor(0).shape;
    _outputShape = _interpreter.getOutputTensor(0).shape;
    print("TFLite model loaded!");
  }

  List<double> runFaceNet(File imageFile) {
    img.Image? image = img.decodeImage(imageFile.readAsBytesSync());
    if (image == null) return [];

    img.Image resizedImage = img.copyResize(image, width: 160, height: 160);
    Float32List input = _imageToFloat32(resizedImage);

    var output = List.filled(_outputShape[1], 0.0).reshape([1, _outputShape[1]]);
    _interpreter.run(input.reshape([1, 160, 160, 3]), output);

    return List<double>.from(output[0]);
  }

  Future<bool> verifyFace(File capturedImage) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return false;

    final doc = await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).get();
    if (!doc.exists || !doc.data()!.containsKey('faceEmbeddings')) {
      print("No face data found for user.");
      return false;
    }

    List<dynamic> storedEmbeddings = doc.get('faceEmbeddings');
    List<double> storedEmbeddingsList = storedEmbeddings.map((e) => e as double).toList();

    List<double> newEmbeddings = runFaceNet(capturedImage);

    double similarity = cosineSimilarity(storedEmbeddingsList, newEmbeddings);
    print("Face similarity score: $similarity");

    return similarity > 0.8;
  }

  double cosineSimilarity(List<double> a, List<double> b) {
    double dotProduct = 0, normA = 0, normB = 0;
    for (int i = 0; i < a.length; i++) {
      dotProduct += a[i] * b[i];
      normA += a[i] * a[i];
      normB += b[i] * b[i];
    }
    return normA == 0 || normB == 0 ? 0 : dotProduct / (sqrt(normA) * sqrt(normB));
  }

  Float32List _imageToFloat32(img.Image image) {
    var buffer = Float32List(160 * 160 * 3);
    int index = 0;
    for (int y = 0; y < 160; y++) {
      for (int x = 0; x < 160; x++) {
        final pixel = image.getPixelSafe(x, y);
        buffer[index++] = pixel.r / 255.0;
        buffer[index++] = pixel.g / 255.0;
        buffer[index++] = pixel.b / 255.0;
      }
    }
    return buffer;
  }

  Future<File> convertImageToFile(img.Image image, String filePath) async {
    Uint8List bytes = Uint8List.fromList(img.encodeJpg(image));
    File file = File(filePath);
    await file.writeAsBytes(bytes);
    return file;
  }
}
