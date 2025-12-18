import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

GeopointFromAddress(String address) async {

    await locationFromAddress(address).then((locations) {
      if (locations.isNotEmpty) {
        final location = locations.first;
        return(GeoPoint(location.latitude, location.longitude));
      }
    }
    );
}

latitudeFromAddress(String address) async {
  double lat = 0.0;
    await locationFromAddress(address).then((locations) {
      if (locations.isNotEmpty) {
        final location = locations.first;
        lat = location.latitude;
      }
    }
    );
    return lat;
}

longitudeFromAddress(String address) async {
  double lon = 0.0;
    await locationFromAddress(address).then((locations) {
      if (locations.isNotEmpty) {
        final location = locations.first;
        lon = location.longitude;
      }
    }
    );
    return lon;
}

DistanceBetweenGeoPoints(GeoPoint point1, GeoPoint point2)  {
// Source - https://stackoverflow.com/a
// Posted by Amit Jangid, modified by community. See post 'Timeline' for change history
// Retrieved 2025-11-24, License - CC BY-SA 4.0
  return(Geolocator.distanceBetween(point1.latitude, point1.longitude, point2.latitude, point2.longitude,).abs());
}
