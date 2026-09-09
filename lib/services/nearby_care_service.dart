import 'dart:convert';

import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

// =============================================================
// MODEL
// =============================================================

class NearbyMedicalFacility {
  final String id;
  final String name;
  final String type;

  final double latitude;
  final double longitude;
  final double distanceKm;

  final String? phone;
  final String? website;
  final String? openingHours;
  final String? speciality;
  final String? address;

  final bool emergency;

  const NearbyMedicalFacility({
    required this.id,
    required this.name,
    required this.type,
    required this.latitude,
    required this.longitude,
    required this.distanceKm,
    this.phone,
    this.website,
    this.openingHours,
    this.speciality,
    this.address,
    this.emergency = false,
  });

  bool get hasPhone =>
      phone != null &&
      phone!.trim().isNotEmpty;

  bool get hasWebsite =>
      website != null &&
      website!.trim().isNotEmpty;
}

// =============================================================
// EXCEPTION
// =============================================================

class NearbyCareException implements Exception {
  final String message;

  const NearbyCareException(
    this.message,
  );

  @override
  String toString() {
    return message;
  }
}

// =============================================================
// SERVICE
// =============================================================

class NearbyCareService {
  static const int defaultRadiusMeters =
      10000;

  // Multiple public endpoints.
  //
  // If one Overpass server rejects the request,
  // Medicare automatically tries another.
  static const List<String>
      _overpassEndpoints = [
    'https://overpass-api.de/api/interpreter',
    'https://overpass.kumi.systems/api/interpreter',
    'https://overpass.nchc.org.tw/api/interpreter',
  ];

  // ============================================================
  // LOCATION
  // ============================================================

  Future<Position>
      getCurrentPosition() async {
    final serviceEnabled =
        await Geolocator
            .isLocationServiceEnabled();

    if (!serviceEnabled) {
      throw const NearbyCareException(
        'Location services are disabled. Please turn on GPS/location services.',
      );
    }

    LocationPermission permission =
        await Geolocator
            .checkPermission();

    if (permission ==
        LocationPermission.denied) {
      permission =
          await Geolocator
              .requestPermission();
    }

    if (permission ==
        LocationPermission.denied) {
      throw const NearbyCareException(
        'Location permission was denied. Medicare needs location access to find nearby hospitals and clinics.',
      );
    }

    if (permission ==
        LocationPermission.deniedForever) {
      throw const NearbyCareException(
        'Location permission is permanently denied. Open app settings and allow location access.',
      );
    }

    return Geolocator
        .getCurrentPosition(
      locationSettings:
          const LocationSettings(
        accuracy:
            LocationAccuracy.high,
        distanceFilter: 0,
      ),
    );
  }

  // ============================================================
  // SEARCH USING CURRENT PHONE LOCATION
  // ============================================================

  Future<List<NearbyMedicalFacility>>
      searchNearby({
    int radiusMeters =
        defaultRadiusMeters,
  }) async {
    final position =
        await getCurrentPosition();

    return searchAroundCoordinates(
      latitude:
          position.latitude,
      longitude:
          position.longitude,
      radiusMeters:
          radiusMeters,
    );
  }

  // ============================================================
  // SEARCH COORDINATES
  // ============================================================

  Future<List<NearbyMedicalFacility>>
      searchAroundCoordinates({
    required double latitude,
    required double longitude,
    int radiusMeters =
        defaultRadiusMeters,
  }) async {
    if (radiusMeters < 500) {
      radiusMeters = 500;
    }

    if (radiusMeters > 50000) {
      radiusMeters = 50000;
    }

    final query =
        _buildOverpassQuery(
      latitude: latitude,
      longitude: longitude,
      radiusMeters:
          radiusMeters,
    );

    http.Response? response;

    Object? lastError;

    for (final endpoint
        in _overpassEndpoints) {
      try {
        response = await http
            .post(
          Uri.parse(endpoint),
          headers: const {
            'Accept':
                'application/json',
            'Content-Type':
                'application/x-www-form-urlencoded; charset=UTF-8',

            // Important:
            // Overpass public instances may reject
            // anonymous requests without identification.
            'User-Agent':
                'Medicare-Patient-Monitor/1.0 (Biomedical Engineering Project)',

            'Referer':
                'https://medicare.local/',
          },
          body: {
            'data': query,
          },
        ).timeout(
          const Duration(
            seconds: 30,
          ),
        );

        if (response.statusCode >=
                200 &&
            response.statusCode <
                300) {
          break;
        }

        lastError =
            'Server $endpoint returned ${response.statusCode}.';

        response = null;
      } catch (e) {
        lastError = e;
        response = null;
      }
    }

    if (response == null) {
      throw NearbyCareException(
        'Nearby medical search failed on all available servers.\n\n$lastError',
      );
    }

    dynamic decoded;

    try {
      decoded =
          jsonDecode(
        response.body,
      );
    } catch (_) {
      throw const NearbyCareException(
        'Nearby medical search returned invalid data.',
      );
    }

    if (decoded is! Map) {
      throw const NearbyCareException(
        'Nearby medical search returned an unexpected response.',
      );
    }

    final elements =
        decoded['elements'];

    if (elements is! List) {
      return [];
    }

    final facilities =
        <NearbyMedicalFacility>[];

    final seen =
        <String>{};

    for (final element
        in elements) {
      if (element is! Map) {
        continue;
      }

      final map =
          Map<dynamic, dynamic>.from(
        element,
      );

      final tagsRaw =
          map['tags'];

      if (tagsRaw is! Map) {
        continue;
      }

      final tags =
          Map<dynamic, dynamic>.from(
        tagsRaw,
      );

      final coordinates =
          _extractCoordinates(
        map,
      );

      if (coordinates == null) {
        continue;
      }

      final facilityLatitude =
          coordinates.$1;

      final facilityLongitude =
          coordinates.$2;

      final type =
          _facilityType(
        tags,
      );

      if (type == null) {
        continue;
      }

      final name =
          _firstNonEmpty([
        tags['name'],
        tags['name:en'],
        tags['operator'],
      ]);

      final displayName =
          name ??
          _fallbackName(
            type,
          );

      final distanceMeters =
          Geolocator.distanceBetween(
        latitude,
        longitude,
        facilityLatitude,
        facilityLongitude,
      );

      final phone =
          _firstNonEmpty([
        tags['contact:phone'],
        tags['phone'],
        tags['telephone'],
        tags['contact:mobile'],
      ]);

      final website =
          _firstNonEmpty([
        tags['contact:website'],
        tags['website'],
        tags['url'],
      ]);

      final openingHours =
          _firstNonEmpty([
        tags['opening_hours'],
      ]);

      final speciality =
          _firstNonEmpty([
        tags[
            'healthcare:speciality'],
        tags['speciality'],
        tags['healthcare'],
      ]);

      final address =
          _buildAddress(
        tags,
      );

      final emergency =
          _isEmergency(
        tags,
      );

      final osmType =
          map['type']
                  ?.toString() ??
              'unknown';

      final osmId =
          map['id']
                  ?.toString() ??
              '';

      final dedupeKey =
          '$osmType:$osmId';

      if (seen.contains(
        dedupeKey,
      )) {
        continue;
      }

      seen.add(
        dedupeKey,
      );

      facilities.add(
        NearbyMedicalFacility(
          id: dedupeKey,
          name: displayName,
          type: type,
          latitude:
              facilityLatitude,
          longitude:
              facilityLongitude,
          distanceKm:
              distanceMeters /
                  1000,
          phone: phone,
          website: website,
          openingHours:
              openingHours,
          speciality:
              speciality,
          address: address,
          emergency:
              emergency,
        ),
      );
    }

    facilities.sort(
      (a, b) =>
          a.distanceKm.compareTo(
        b.distanceKm,
      ),
    );

    return facilities;
  }

  // ============================================================
  // OVERPASS QUERY
  // ============================================================

  String _buildOverpassQuery({
    required double latitude,
    required double longitude,
    required int radiusMeters,
  }) {
    return '''
[out:json][timeout:25];

(
  nwr["amenity"="hospital"](around:$radiusMeters,$latitude,$longitude);

  nwr["amenity"="clinic"](around:$radiusMeters,$latitude,$longitude);

  nwr["amenity"="doctors"](around:$radiusMeters,$latitude,$longitude);

  nwr["healthcare"="hospital"](around:$radiusMeters,$latitude,$longitude);

  nwr["healthcare"="clinic"](around:$radiusMeters,$latitude,$longitude);

  nwr["healthcare"="doctor"](around:$radiusMeters,$latitude,$longitude);

  nwr["healthcare"="doctors"](around:$radiusMeters,$latitude,$longitude);
);

out center tags;
''';
  }

  // ============================================================
  // TYPE
  // ============================================================

  String? _facilityType(
    Map<dynamic, dynamic> tags,
  ) {
    final amenity =
        tags['amenity']
            ?.toString()
            .toLowerCase();

    final healthcare =
        tags['healthcare']
            ?.toString()
            .toLowerCase();

    if (amenity ==
            'hospital' ||
        healthcare ==
            'hospital') {
      return 'Hospital';
    }

    if (amenity ==
            'clinic' ||
        healthcare ==
            'clinic') {
      return 'Clinic';
    }

    if (amenity ==
            'doctors' ||
        healthcare ==
            'doctor' ||
        healthcare ==
            'doctors') {
      return 'Doctor';
    }

    return null;
  }

  // ============================================================
  // FALLBACK NAME
  // ============================================================

  String _fallbackName(
    String type,
  ) {
    switch (type) {
      case 'Hospital':
        return 'Nearby Hospital';

      case 'Clinic':
        return 'Nearby Clinic';

      case 'Doctor':
        return 'Medical Practice';

      default:
        return 'Medical Facility';
    }
  }

  // ============================================================
  // COORDINATES
  // ============================================================

  (double, double)?
      _extractCoordinates(
    Map<dynamic, dynamic> map,
  ) {
    final lat =
        _toDouble(
      map['lat'],
    );

    final lon =
        _toDouble(
      map['lon'],
    );

    if (lat != null &&
        lon != null) {
      return (
        lat,
        lon,
      );
    }

    final centerRaw =
        map['center'];

    if (centerRaw is Map) {
      final center =
          Map<dynamic, dynamic>.from(
        centerRaw,
      );

      final centerLat =
          _toDouble(
        center['lat'],
      );

      final centerLon =
          _toDouble(
        center['lon'],
      );

      if (centerLat != null &&
          centerLon != null) {
        return (
          centerLat,
          centerLon,
        );
      }
    }

    return null;
  }

  // ============================================================
  // ADDRESS
  // ============================================================

  String? _buildAddress(
    Map<dynamic, dynamic> tags,
  ) {
    final parts =
        <String>[];

    final houseNumber =
        _stringOrNull(
      tags['addr:housenumber'],
    );

    final street =
        _stringOrNull(
      tags['addr:street'],
    );

    final suburb =
        _stringOrNull(
      tags['addr:suburb'],
    );

    final district =
        _stringOrNull(
      tags['addr:district'],
    );

    final city =
        _stringOrNull(
      tags['addr:city'],
    );

    if (houseNumber != null ||
        street != null) {
      final line = [
        houseNumber,
        street,
      ].whereType<String>().join(
            ' ',
          );

      if (line.isNotEmpty) {
        parts.add(line);
      }
    }

    if (suburb != null) {
      parts.add(suburb);
    }

    if (district != null &&
        district != suburb) {
      parts.add(district);
    }

    if (city != null) {
      parts.add(city);
    }

    if (parts.isEmpty) {
      return _stringOrNull(
        tags['addr:full'],
      );
    }

    return parts.join(
      ', ',
    );
  }

  // ============================================================
  // EMERGENCY
  // ============================================================

  bool _isEmergency(
    Map<dynamic, dynamic> tags,
  ) {
    final value =
        tags['emergency']
            ?.toString()
            .toLowerCase();

    if (value == 'yes' ||
        value ==
            'emergency_department') {
      return true;
    }

    final emergencyDepartment =
        tags[
                'emergency:department']
            ?.toString()
            .toLowerCase();

    return emergencyDepartment ==
        'yes';
  }

  // ============================================================
  // CALL
  // ============================================================

  Future<bool> callFacility(
    NearbyMedicalFacility facility,
  ) async {
    final rawPhone =
        facility.phone;

    if (rawPhone == null ||
        rawPhone.trim().isEmpty) {
      return false;
    }

    final normalized =
        _normalizePhone(
      rawPhone,
    );

    if (normalized.isEmpty) {
      return false;
    }

    final uri =
        Uri(
      scheme: 'tel',
      path: normalized,
    );

    if (!await canLaunchUrl(
      uri,
    )) {
      return false;
    }

    return launchUrl(
      uri,
    );
  }

  // ============================================================
  // MAP
  // ============================================================

  Future<bool> openMap(
    NearbyMedicalFacility facility,
  ) async {
    final label =
        Uri.encodeComponent(
      facility.name,
    );

    final uri =
        Uri.parse(
      'https://www.google.com/maps/search/?api=1'
      '&query=${facility.latitude},${facility.longitude}'
      '&query_place_id=$label',
    );

    if (await canLaunchUrl(
      uri,
    )) {
      return launchUrl(
        uri,
        mode:
            LaunchMode.externalApplication,
      );
    }

    final fallback =
        Uri.parse(
      'https://www.openstreetmap.org/'
      '?mlat=${facility.latitude}'
      '&mlon=${facility.longitude}'
      '#map=17/'
      '${facility.latitude}/'
      '${facility.longitude}',
    );

    return launchUrl(
      fallback,
      mode:
          LaunchMode.externalApplication,
    );
  }

  // ============================================================
  // WEBSITE
  // ============================================================

  Future<bool> openWebsite(
    NearbyMedicalFacility facility,
  ) async {
    final website =
        facility.website;

    if (website == null ||
        website.trim().isEmpty) {
      return false;
    }

    var raw =
        website.trim();

    if (!raw.startsWith(
          'http://',
        ) &&
        !raw.startsWith(
          'https://',
        )) {
      raw =
          'https://$raw';
    }

    final uri =
        Uri.tryParse(raw);

    if (uri == null) {
      return false;
    }

    if (!await canLaunchUrl(
      uri,
    )) {
      return false;
    }

    return launchUrl(
      uri,
      mode:
          LaunchMode.externalApplication,
    );
  }

  // ============================================================
  // SETTINGS
  // ============================================================

  Future<bool>
      openLocationSettings() {
    return Geolocator
        .openLocationSettings();
  }

  Future<bool>
      openAppSettings() {
    return Geolocator
        .openAppSettings();
  }

  // ============================================================
  // HELPERS
  // ============================================================

  double? _toDouble(
    dynamic value,
  ) {
    if (value == null) {
      return null;
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
      value.toString(),
    );
  }

  String? _firstNonEmpty(
    List<dynamic> values,
  ) {
    for (final value
        in values) {
      final text =
          _stringOrNull(
        value,
      );

      if (text != null) {
        return text;
      }
    }

    return null;
  }

  String? _stringOrNull(
    dynamic value,
  ) {
    if (value == null) {
      return null;
    }

    final text =
        value
            .toString()
            .trim();

    if (text.isEmpty) {
      return null;
    }

    return text;
  }

  String _normalizePhone(
    String phone,
  ) {
    var value =
        phone.trim();

    if (value.contains(';')) {
      value =
          value
              .split(';')
              .first
              .trim();
    }

    value =
        value.replaceAll(
      RegExp(
        r'[^0-9+]',
      ),
      '',
    );

    return value;
  }
}