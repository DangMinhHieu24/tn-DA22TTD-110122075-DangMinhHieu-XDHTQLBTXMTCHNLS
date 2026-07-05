import 'package:latlong2/latlong.dart';

class ServiceStation {
  final String id;
  final String name;
  final String address;
  final LatLng location;
  final String phone;
  final String imageUrl;

  const ServiceStation({
    required this.id,
    required this.name,
    required this.address,
    required this.location,
    this.phone = '',
    this.imageUrl = '',
  });
}

final List<ServiceStation> mockStations = [
  ServiceStation(
    id: 'st-1',
    name: 'Xanh EV Repair - Chi nhánh Trà Vinh',
    address: '123 Nguyễn Thị Minh Khai, P.7, TP. Trà Vinh',
    location: const LatLng(9.9328, 106.3353),
    phone: '0976 985 305',
  ),
];
