import 'dart:async';
import 'dart:convert';
import 'dart:isolate';
import 'dart:ui';
import 'package:background_locator_2/location_dto.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocationServiceRepository {
  static const String _kLocationKey = 'background_location';
  static const String _kPortName = 'location_port';

  static LocationServiceRepository? _instance;
  factory LocationServiceRepository() {
    _instance ??= LocationServiceRepository._();
    return _instance!;
  }

  LocationServiceRepository._();

  Future<void> init(Map<dynamic, dynamic> params) async {
    final SendPort? send = IsolateNameServer.lookupPortByName(_kPortName);
    if (send != null) {
      // Send initial data if needed
    }
  }

  Future<void> dispose() async {
    // Clean up if needed
  }

  Future<void> callback(LocationDto locationDto) async {
    final SendPort? send = IsolateNameServer.lookupPortByName(_kPortName);
    send?.send(locationDto.toJson());
    await _saveLocation(locationDto);
  }

  Future<void> _saveLocation(LocationDto location) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> locations = prefs.getStringList(_kLocationKey) ?? [];
    locations.add(jsonEncode(location.toJson()));
    await prefs.setStringList(_kLocationKey, locations);
  }

  static Stream<LocationDto> get locationStream {
    final ReceivePort port = ReceivePort();
    IsolateNameServer.registerPortWithName(port.sendPort, _kPortName);
    return port.map((message) => LocationDto.fromJson(message as Map<String, dynamic>));
  }
}
