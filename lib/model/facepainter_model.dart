import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class FacePainter extends CustomPainter {
  FacePainter(this.faces, this.imageSize, {this.isFrontCamera = true});

  final List<Face> faces;
  final Size imageSize;
  final bool isFrontCamera;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    double scaleX = size.width / imageSize.width;
    double scaleY = size.height / imageSize.height;

    for (var face in faces) {
      Rect rect = face.boundingBox;
      
      double left = rect.left * scaleX;
      double top = rect.top * scaleY;
      double right = rect.right * scaleX;
      double bottom = rect.bottom * scaleY;

      if (isFrontCamera) {
        double tempLeft = left;
        left = size.width - right;
        right = size.width - tempLeft;
      }

      left = left.clamp(0, size.width);
      right = right.clamp(0, size.width);
      top = top.clamp(0, size.height);
      bottom = bottom.clamp(0, size.height);

      Rect scaledRect = Rect.fromLTRB(left, top, right, bottom);

      canvas.drawRect(scaledRect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}