import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return MapPageState();
  }
}

class MapPageState extends State<MapPage> {
  GoogleMapController mapController;
  // London
  final LatLng center = LatLng(51.507351, -0.127758);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: GoogleMap(
          onMapCreated: _onMapCreated,
          options: GoogleMapOptions(
            scrollGesturesEnabled: true,
            zoomGesturesEnabled: true,
            cameraPosition: CameraPosition(
              target: center,
              zoom: 11.0,
            ),
          ),
        ),
      ),
    );
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;

    mapController.addMarker(
      MarkerOptions(
        position: center,
        infoWindowText: InfoWindowText('TITLE', 'SNIPPET'),
      ),
    );
  }
}
