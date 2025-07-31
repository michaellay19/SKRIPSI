package com.example.skripsi

import android.location.Location
import android.location.LocationManager
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.example.mocklocation"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler {
            call, result ->
            if (call.method == "isMockLocation") {
                try {
                    val locationManager = getSystemService(LOCATION_SERVICE) as LocationManager
                    val providers = locationManager.getProviders(true)

                    for (provider in providers) {
                        val location = locationManager.getLastKnownLocation(provider)
                        if (location != null) {
                            val isMock = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                                location.isMock
                            } else {
                                location.isFromMockProvider
                            }

                            if (isMock) {
                                result.success(true)
                                return@setMethodCallHandler
                            }
                        }
                    }

                    result.success(false)
                } catch (e: Exception) {
                    result.error("MOCK_LOCATION_ERROR", "Error checking mock location: ${e.localizedMessage}", null)
                }
            } else {
                result.notImplemented()
            }
        }
    }
}
