import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class AdminLocationPage extends StatefulWidget {
  const AdminLocationPage({super.key});

  @override
  State<AdminLocationPage> createState() => _AdminLocationPageState();
}

class _AdminLocationPageState extends State<AdminLocationPage> {
  late GoogleMapController mapController;
  final LatLng _center = const LatLng(-6.200000, 106.816666);
  double radius = 1500;

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'PT. SURYA CEMERLANG LOGISTIK',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: GoogleMap(
                  onMapCreated: _onMapCreated,
                  initialCameraPosition: CameraPosition(
                    target: _center,
                    zoom: 14.0,
                  ),
                  markers: {
                    Marker(
                      markerId: const MarkerId('center'),
                      position: _center,
                    )
                  },
                  circles: {
                    Circle(
                      circleId: const CircleId('radius'),
                      center: _center,
                      radius: radius,
                      fillColor: Colors.blue.withOpacity(0.3),
                      strokeWidth: 1,
                      strokeColor: Colors.blue,
                    ),
                  },
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: radius.toString(),
                    decoration: const InputDecoration(
                      labelText: 'Radius',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      setState(() {
                        radius = double.tryParse(value) ?? 1500;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Latitude: ${_center.latitude}'),
                      Text('Longitude: ${_center.longitude}'),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Simpan',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
