import 'package:flutter/services.dart';

class MockLocationChecker {
  static const MethodChannel _channel = MethodChannel('com.example.mocklocation');

  static Future<bool> isLocationMocked() async {
    try {
      final result = await _channel.invokeMethod('isMockLocation');
      return result == true;
    } catch (e) {
      print('Error checking mock location: $e');
      return false;
    }
  }
}