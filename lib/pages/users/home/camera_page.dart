import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:skripsi/model/facepainter_model.dart';
import 'package:skripsi/pages/users/home/home_page.dart';
import 'package:skripsi/provider/camera_provider.dart';
import 'package:skripsi/model/facenet_model_mobile.dart'
    if (dart.library.html) 'package:skripsi/model/facenet_model_web.dart';

class CameraPage extends StatefulWidget {
  final String activityType;

  const CameraPage({super.key, required this.activityType});

  @override
  CameraPageState createState() => CameraPageState();
}

class CameraPageState extends State<CameraPage> {
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;
  FaceNetModel faceNet = FaceNetModel();
  late FaceDetector _faceDetector;
  bool isDetecting = false;
  List<Face> detectedFaces = [];
  Timer? _debounceTimer;
  List<bool> livenessFrames = [];
  List<bool> eyeOpenStates = [];
  List<bool> smileStates = [];
  List<double> headAngles = [];

  @override
  void initState() {
    super.initState();
    _faceDetector = FaceDetector(
        options: FaceDetectorOptions(
      enableClassification: true,
      enableContours: true,
      enableTracking: true,
      performanceMode: FaceDetectorMode.accurate,
    ));
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    bool granted = await requestCameraPermission();
    if (!granted) return;

    final cameras = await availableCameras();
    for (var camera in cameras) {
      if (camera.lensDirection == CameraLensDirection.front) {
        _controller = CameraController(
          camera,
          ResolutionPreset.medium,
          enableAudio: false,
        );

        _initializeControllerFuture = _controller!.initialize().then((_) {
          if (mounted) {
            setState(() {});
            Future.delayed(const Duration(milliseconds: 500), () {
              _startFaceDetection();
            });
          }
        });
        break;
      }
    }
  }

  Future<void> _startFaceDetection() async {
    if (_controller == null || isDetecting) return;
    isDetecting = true;

    _controller!.startImageStream((CameraImage image) async {
      if (!mounted || _controller == null) return;

      if (_debounceTimer?.isActive ?? false) return;
      _debounceTimer = Timer(const Duration(milliseconds: 400), () async {
        final WriteBuffer allBytes = WriteBuffer();
        for (Plane plane in image.planes) {
          allBytes.putUint8List(plane.bytes);
        }
        final bytes = allBytes.done().buffer.asUint8List();

        final InputImage inputImage = InputImage.fromBytes(
          bytes: bytes,
          metadata: InputImageMetadata(
            size: Size(image.width.toDouble(), image.height.toDouble()),
            rotation: InputImageRotation.rotation270deg,
            format: InputImageFormat.nv21,
            bytesPerRow: image.planes[0].bytesPerRow,
          ),
        );

        final faces = await _faceDetector.processImage(inputImage);

        if (mounted) {
          setState(() {
            detectedFaces = faces;
          });
          if (faces.isNotEmpty) {
            bool isLive = checkLiveness(faces);
            if (isLive && !isDetecting) {
              print("✅ Stopping stream after confirming liveness.");
              await _controller!.stopImageStream();
            }
          }
        }
      });
    });
  }

  bool detectBlink(List<Face> faces) {
    if (faces.isEmpty) return false;

    Face face = faces.first;
    double leftEyeOpen = face.leftEyeOpenProbability ?? 1.0;
    double rightEyeOpen = face.rightEyeOpenProbability ?? 1.0;

    if (eyeOpenStates.length >= 5) {
      eyeOpenStates.removeAt(0);
    }
    eyeOpenStates.add(leftEyeOpen > 0.6 && rightEyeOpen > 0.6);

    if (eyeOpenStates.length >= 3 &&
        eyeOpenStates[0] == true &&
        eyeOpenStates[1] == false &&
        eyeOpenStates[2] == true) {
      print("✅ Blink detected!");
      return true;
    }
    return false;
  }

  bool detectSmile(List<Face> faces) {
    if (faces.isEmpty) return false;

    Face face = faces.first;
    double smileProb = face.smilingProbability ?? 0.0;

    if (smileStates.length >= 5) {
      smileStates.removeAt(0);
    }
    smileStates.add(smileProb > 0.4);

    if (smileStates.where((s) => s).length >= 3) {
      print("✅ Smile detected!");
      return true;
    }
    return false;
  }

  bool detectHeadMovement(List<Face> faces) {
    if (faces.isEmpty) return false;

    Face face = faces.first;
    double headY = face.headEulerAngleY ?? 0.0;
    double headZ = face.headEulerAngleZ ?? 0.0;

    if (headAngles.length >= 5) {
      headAngles.removeAt(0);
    }
    headAngles.add((headY.abs() + headZ.abs()) / 2);

    if (headAngles.length >= 3 && (headAngles.last - headAngles.first).abs() > 15) {
      print("✅ Head movement detected!");
      return true;
    }
    return false;
  }

  bool detectFakeFace(Face face) {
    if (face.contours[FaceContourType.face] == null || face.contours[FaceContourType.face]!.points.isEmpty) {
      print("⚠️ No contour data available. Cannot determine if face is fake.");
      return false;
    }

    if (face.contours[FaceContourType.face]!.points.length < 10) {
      print("❌ Fake face detected! (Photo/Action Figure)");
      return true;
    }
    return false;
  }

  bool checkLiveness(List<Face> faces) {
    if (faces.isEmpty) return false;

    Face face = faces.first;
    bool blinked = detectBlink(faces);
    bool smiled = detectSmile(faces);
    bool movedHead = detectHeadMovement(faces);
    bool isFake = detectFakeFace(face);

    if (isFake) return false;

    int liveActions = [blinked, smiled, movedHead].where((x) => x).length;

    if (liveActions > 0) {
      livenessFrames.add(true);
      if (livenessFrames.length > 5) {
        livenessFrames.removeAt(0);
      }
    }

    return livenessFrames.where((frame) => frame).length >= 2;
  }

  void _captureAndDetectFace() async {
    if (detectedFaces.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No face detected. Try again!")),
      );
      return;
    }

    if (livenessFrames.where((frame) => frame).length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Liveness check failed! Blink, Smile, or Move Head.")),
      );
      return;
    }

    try {
      setState(() {
        isDetecting = true;
      });

      await _initializeControllerFuture;
      await _controller!.stopImageStream();
      await Future.delayed(const Duration(milliseconds: 300));

      final image = await _controller!.takePicture();
      final imageFile = File(image.path);

      File? croppedFaceFile = await _cropDetectedFace(imageFile);

      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      if (widget.activityType == 'Face Register') {
        await saveFaceData(croppedFaceFile!, currentUser);
      } else {
        bool isVerified = await faceNet.verifyFace(croppedFaceFile!);
        if (isVerified) {
          await Provider.of<CameraProvider>(context, listen: false).uploadImage(croppedFaceFile, widget.activityType);
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Face not recognized. Try again!")),
          );
          _restartFaceDetection();
        }
      }
    } catch (e) {
      print('Error capturing face: $e');
    } finally {
      setState(() {
        isDetecting = false;
      });
    }
  }

  void _restartFaceDetection() {
    setState(() {
      detectedFaces = [];
      isDetecting = false;
    });

    Future.delayed(const Duration(milliseconds: 500), () {
      if (_controller != null) {
        _startFaceDetection();
      }
    });
  }

  Future<File?> _cropDetectedFace(File imageFile) async {
    try {
      img.Image? fullImage = img.decodeImage(await imageFile.readAsBytes());
      if (fullImage == null || detectedFaces.isEmpty) return null;

      Face face = detectedFaces[0];
      Rect faceRect = face.boundingBox;

      double scaleX = fullImage.width / _controller!.value.previewSize!.height;
      double scaleY = fullImage.height / _controller!.value.previewSize!.width;

      int x = (faceRect.left * scaleX).toInt().clamp(0, fullImage.width);
      int y = (faceRect.top * scaleY).toInt().clamp(0, fullImage.height);
      int width = (faceRect.width * scaleX).toInt().clamp(1, fullImage.width - x);
      int height = (faceRect.height * scaleY).toInt().clamp(1, fullImage.height - y);

      img.Image croppedFace = img.copyCrop(fullImage, x: x, y: y, width: width, height: height);

      if (_controller!.description.lensDirection == CameraLensDirection.front) {
        croppedFace = img.flipHorizontal(croppedFace);
      }

      final String croppedPath = '${imageFile.path}_cropped.jpg';
      File croppedFile = File(croppedPath)..writeAsBytesSync(img.encodeJpg(croppedFace));

      print("Face successfully cropped and saved!");
      return croppedFile;
    } catch (e) {
      print("Error cropping face: $e");
      return null;
    }
  }

  Future<void> saveFaceData(File imageFile, User currentUser) async {
    setState(() {
      isDetecting = true;
    });

    List<double> embeddings = faceNet.runFaceNet(imageFile);
    final storageRef = FirebaseStorage.instance.ref().child('users/${currentUser.uid}/face/${currentUser.uid}.jpg');

    await storageRef.putFile(imageFile);
    final downloadUrl = await storageRef.getDownloadURL();

    await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).set({
      'faceImage': downloadUrl,
      'faceEmbeddings': embeddings,
    }, SetOptions(merge: true));

    setState(() {
      isDetecting = false;
    });

    print("Profile image captured and saved!");
    print("embeddings : $embeddings");

    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const HomePage()));
  }

  void processImage(File image) async {
    img.Image? fullImage = img.decodeImage(image.readAsBytesSync());
    if (fullImage == null || detectedFaces.isEmpty) return;

    final bool isFrontCamera = _controller!.description.lensDirection == CameraLensDirection.front;
    if (isFrontCamera) {
      fullImage = img.flipHorizontal(fullImage);
      print("Image flipped for front camera correction.");
    }

    Face face = detectedFaces[0];
    img.Image croppedFace = img.copyCrop(
      fullImage,
      x: face.boundingBox.left.toInt(),
      y: face.boundingBox.top.toInt(),
      width: face.boundingBox.width.toInt(),
      height: face.boundingBox.height.toInt(),
    );

    File croppedFile = await faceNet.convertImageToFile(croppedFace, '${image.path}_cropped.jpg');

    List<double> embeddings = faceNet.runFaceNet(croppedFile);
    print("Cropped Face Embeddings: $embeddings");
  }

  Future<bool> requestCameraPermission() async {
    var status = await Permission.camera.request();
    if (status.isPermanentlyDenied) {
      openAppSettings();
      return false;
    }
    return status.isGranted;
  }

  @override
  void dispose() {
    _controller?.dispose();
    _faceDetector.close();
    isDetecting = false;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: FutureBuilder<void>(
              future: _initializeControllerFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  return CameraPreview(_controller!);
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else {
                  return const Center(child: CircularProgressIndicator());
                }
              },
            ),
          ),
          if (detectedFaces.isNotEmpty)
            Positioned.fill(
              child: SizedBox(
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height,
                child: CustomPaint(
                  painter: FacePainter(
                    detectedFaces,
                    Size(
                      _controller!.value.previewSize!.height,
                      _controller!.value.previewSize!.width,
                    ),
                    isFrontCamera: true,
                  ),
                ),
              ),
            ),
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Center(
              child: FloatingActionButton(
                onPressed: _captureAndDetectFace,
                child: const Icon(Icons.camera),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
