import 'dart:io';
import 'package:image/image.dart' as img;

class FaceNetModel {
  Future<bool> verifyFace(File capturedImage) async {
    print("Face verification is disabled on Web.");
    return false;
  }

  List<double> runFaceNet(File imageFile) {
    print("TFLite is disabled on Web.");
    return [];
  }

  Future<File> convertImageToFile(img.Image image, String filePath) async {
    print("Image conversion is disabled on Web.");
    return File(filePath);
  }
}