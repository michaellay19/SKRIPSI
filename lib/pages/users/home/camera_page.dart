import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../../../provider/camera_provider.dart';

class CameraPage extends StatefulWidget {
  final String activityType;

  const CameraPage({super.key, required this.activityType});
  
  @override
  CameraPageState createState() => CameraPageState();
}

class CameraPageState extends State<CameraPage> {
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;

  @override
  void initState() {
    super.initState();
    requestCameraPermission().then((granted) {
      if (granted) {
        availableCameras().then((cameras) {
          if (cameras.isNotEmpty) {
            _controller = CameraController(
              cameras[0],
              ResolutionPreset.high,
            );
            _initializeControllerFuture = _controller!.initialize();
            setState(() {});
          } else {
            print('No cameras available');
          }
        }).catchError((e) {
          print('Error accessing cameras: $e');
        });
      } else {
        print('Camera permission denied');
      }
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<bool> requestCameraPermission() async {
    var status = await Permission.camera.status;
    if (!status.isGranted) {
      await Permission.camera.request();
      status = await Permission.camera.status;
    }
    return status.isGranted;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          FutureBuilder<void>(
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
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20.0),
              child: FloatingActionButton(
                onPressed: () async {
                  try {
                    await _initializeControllerFuture;
                    final image = await _controller!.takePicture();
                    await Provider.of<CameraProvider>(context, listen: false)
                        .uploadImage(File(image.path), widget.activityType);
                    Navigator.pop(context);
                  } catch (e) {
                    print('Error: $e');
                  }
                },
                child: const Icon(Icons.camera),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
