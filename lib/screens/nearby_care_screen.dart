import 'package:flutter/material.dart';

import '../services/nearby_care_service.dart';

class NearbyCareScreen extends StatefulWidget {
  const NearbyCareScreen({super.key});

  @override
  State<NearbyCareScreen> createState() =>
      _NearbyCareScreenState();
}

class _NearbyCareScreenState extends State<NearbyCareScreen> {
  final NearbyCareService _service =
      NearbyCareService();

  bool _loading = true;

  String? _error;

  List<NearbyMedicalFacility> _facilities = [];

  String _selectedType = 'All';

  int _radiusMeters = 10000;

  final List<String> _types = [
    'All',
    'Hospital',
    'Clinic',
    'Doctor',
  ];

  @override
  void initState() {
    super.initState();

    _loadNearbyCare();
  }

  // ============================================================
  // LOAD FACILITIES
  // ============================================================

  Future<void> _loadNearbyCare() async {
    if (_loading == false) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final results =
          await _service.searchNearby(
        radiusMeters:
            _radiusMeters,
      );

      if (!mounted) return;

      setState(() {
        _facilities = results;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  // ============================================================
  // FILTERED FACILITIES
  // ============================================================

  List<NearbyMedicalFacility>
      get _filteredFacilities {
    if (_selectedType == 'All') {
      return _facilities;
    }

    return _facilities
        .where(
          (facility) =>
              facility.type ==
              _selectedType,
        )
        .toList();
  }

  // ============================================================
  // COUNT HELPERS
  // ============================================================

  int _countType(
    String type,
  ) {
    return _facilities
        .where(
          (facility) =>
              facility.type == type,
        )
        .length;
  }

  int get _phoneCount {
    return _facilities
        .where(
          (facility) =>
              facility.hasPhone,
        )
        .length;
  }

  // ============================================================
  // CALL
  // ============================================================

  Future<void> _callFacility(
    NearbyMedicalFacility facility,
  ) async {
    final success =
        await _service.callFacility(
      facility,
    );

    if (!mounted) return;

    if (!success) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'A callable phone number is not available for this facility.',
          ),
        ),
      );
    }
  }

  // ============================================================
  // MAP
  // ============================================================

  Future<void> _openMap(
    NearbyMedicalFacility facility,
  ) async {
    final success =
        await _service.openMap(
      facility,
    );

    if (!mounted) return;

    if (!success) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to open the map.',
          ),
        ),
      );
    }
  }

  // ============================================================
  // WEBSITE
  // ============================================================

  Future<void> _openWebsite(
    NearbyMedicalFacility facility,
  ) async {
    final success =
        await _service.openWebsite(
      facility,
    );

    if (!mounted) return;

    if (!success) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to open this website.',
          ),
        ),
      );
    }
  }

  // ============================================================
  // LOCATION SETTINGS
  // ============================================================

  Future<void> _openLocationSettings() async {
    await _service.openLocationSettings();
  }

  Future<void> _openAppSettings() async {
    await _service.openAppSettings();
  }

  // ============================================================
  // CHANGE RADIUS
  // ============================================================

  Future<void> _changeRadius() async {
    final result =
        await showModalBottomSheet<int>(
      context: context,
      backgroundColor:
          Colors.transparent,
      builder: (context) {
        return Container(
          padding:
              const EdgeInsets.fromLTRB(
            20,
            12,
            20,
            30,
          ),
          decoration:
              const BoxDecoration(
            color: Colors.white,
            borderRadius:
                BorderRadius.vertical(
              top:
                  Radius.circular(
                28,
              ),
            ),
          ),
          child: Column(
            mainAxisSize:
                MainAxisSize.min,
            children: [
              Container(
                width: 45,
                height: 5,
                decoration:
                    BoxDecoration(
                  color:
                      Colors.grey.shade300,
                  borderRadius:
                      BorderRadius.circular(
                    20,
                  ),
                ),
              ),

              const SizedBox(
                height: 20,
              ),

              const Text(
                'Search Distance',
                style: TextStyle(
                  color:
                      Color(
                    0xFF082B5C,
                  ),
                  fontSize: 20,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              const SizedBox(
                height: 8,
              ),

              const Text(
                'Choose how far Medicare should search for healthcare facilities.',
                textAlign:
                    TextAlign.center,
                style: TextStyle(
                  color:
                      Colors.blueGrey,
                  fontSize: 12,
                ),
              ),

              const SizedBox(
                height: 18,
              ),

              _RadiusOption(
                title: '5 km',
                selected:
                    _radiusMeters ==
                        5000,
                onTap: () {
                  Navigator.pop(
                    context,
                    5000,
                  );
                },
              ),

              _RadiusOption(
                title: '10 km',
                selected:
                    _radiusMeters ==
                        10000,
                onTap: () {
                  Navigator.pop(
                    context,
                    10000,
                  );
                },
              ),

              _RadiusOption(
                title: '20 km',
                selected:
                    _radiusMeters ==
                        20000,
                onTap: () {
                  Navigator.pop(
                    context,
                    20000,
                  );
                },
              ),

              _RadiusOption(
                title: '30 km',
                selected:
                    _radiusMeters ==
                        30000,
                onTap: () {
                  Navigator.pop(
                    context,
                    30000,
                  );
                },
              ),
            ],
          ),
        );
      },
    );

    if (result == null ||
        result == _radiusMeters) {
      return;
    }

    setState(() {
      _radiusMeters = result;
    });

    await _loadNearbyCare();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    const navy =
        Color(0xFF082B5C);

    const blue =
        Color(0xFF0968D8);

    const background =
        Color(0xFFF5F8FC);

    return Scaffold(
      backgroundColor:
          background,
      appBar: AppBar(
        backgroundColor:
            background,
        surfaceTintColor:
            Colors.transparent,
        title: const Text(
          'Nearby Care',
          style: TextStyle(
            color: navy,
            fontWeight:
                FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            tooltip:
                'Search distance',
            onPressed:
                _loading
                    ? null
                    : _changeRadius,
            icon: const Icon(
              Icons
                  .radar_rounded,
            ),
          ),
          IconButton(
            tooltip:
                'Refresh',
            onPressed:
                _loading
                    ? null
                    : _loadNearbyCare,
            icon: const Icon(
              Icons
                  .refresh_rounded,
            ),
          ),
        ],
      ),

      body: _loading
          ? _buildLoading()
          : _error != null
              ? _buildError()
              : RefreshIndicator(
                  onRefresh:
                      _loadNearbyCare,
                  child: ListView(
                    physics:
                        const AlwaysScrollableScrollPhysics(),
                    padding:
                        const EdgeInsets.fromLTRB(
                      18,
                      8,
                      18,
                      35,
                    ),
                    children: [
                      // ===========================================
                      // HEADER
                      // ===========================================

                      Container(
                        padding:
                            const EdgeInsets.all(
                          22,
                        ),
                        decoration:
                            BoxDecoration(
                          gradient:
                              const LinearGradient(
                            begin:
                                Alignment.topLeft,
                            end:
                                Alignment.bottomRight,
                            colors: [
                              navy,
                              blue,
                            ],
                          ),
                          borderRadius:
                              BorderRadius.circular(
                            27,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 58,
                              height: 58,
                              decoration:
                                  BoxDecoration(
                                color:
                                    Colors.white.withValues(
                                  alpha: 0.15,
                                ),
                                borderRadius:
                                    BorderRadius.circular(
                                  18,
                                ),
                              ),
                              child:
                                  const Icon(
                                Icons
                                    .local_hospital_rounded,
                                color:
                                    Colors.white,
                                size: 34,
                              ),
                            ),

                            const SizedBox(
                              width: 15,
                            ),

                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Care Around You',
                                    style:
                                        TextStyle(
                                      color:
                                          Colors.white,
                                      fontSize:
                                          22,
                                      fontWeight:
                                          FontWeight.bold,
                                    ),
                                  ),

                                  const SizedBox(
                                    height: 5,
                                  ),

                                  Text(
                                    'Searching within ${(_radiusMeters / 1000).round()} km of your current location.',
                                    style:
                                        const TextStyle(
                                      color:
                                          Colors.white70,
                                      fontSize:
                                          12,
                                      height:
                                          1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(
                        height: 18,
                      ),

                      // ===========================================
                      // SUMMARY
                      // ===========================================

                      Row(
                        children: [
                          Expanded(
                            child:
                                _SummaryCard(
                              icon: Icons
                                  .local_hospital_outlined,
                              title:
                                  'Hospitals',
                              value:
                                  '${_countType('Hospital')}',
                            ),
                          ),

                          const SizedBox(
                            width: 8,
                          ),

                          Expanded(
                            child:
                                _SummaryCard(
                              icon: Icons
                                  .medical_services_outlined,
                              title:
                                  'Clinics',
                              value:
                                  '${_countType('Clinic')}',
                            ),
                          ),

                          const SizedBox(
                            width: 8,
                          ),

                          Expanded(
                            child:
                                _SummaryCard(
                              icon: Icons
                                  .phone_outlined,
                              title:
                                  'Numbers',
                              value:
                                  '$_phoneCount',
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(
                        height: 20,
                      ),

                      // ===========================================
                      // FILTERS
                      // ===========================================

                      const Text(
                        'Nearby Facilities',
                        style:
                            TextStyle(
                          color: navy,
                          fontSize: 20,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),

                      const SizedBox(
                        height: 12,
                      ),

                      SingleChildScrollView(
                        scrollDirection:
                            Axis.horizontal,
                        child: Row(
                          children:
                              _types.map(
                            (type) {
                              final selected =
                                  _selectedType ==
                                      type;

                              return Padding(
                                padding:
                                    const EdgeInsets.only(
                                  right: 8,
                                ),
                                child:
                                    ChoiceChip(
                                  label:
                                      Text(
                                    type,
                                  ),
                                  selected:
                                      selected,
                                  onSelected:
                                      (_) {
                                    setState(
                                      () {
                                        _selectedType =
                                            type;
                                      },
                                    );
                                  },
                                  selectedColor:
                                      blue,
                                  backgroundColor:
                                      Colors.white,
                                  labelStyle:
                                      TextStyle(
                                    color: selected
                                        ? Colors.white
                                        : navy,
                                    fontWeight:
                                        FontWeight.w600,
                                  ),
                                  side:
                                      BorderSide(
                                    color: selected
                                        ? blue
                                        : const Color(
                                            0xFFE0E7EF,
                                          ),
                                  ),
                                  showCheckmark:
                                      false,
                                ),
                              );
                            },
                          ).toList(),
                        ),
                      ),

                      const SizedBox(
                        height: 14,
                      ),

                      // ===========================================
                      // EMPTY RESULT
                      // ===========================================

                      if (_filteredFacilities
                          .isEmpty)
                        Container(
                          padding:
                              const EdgeInsets.all(
                            25,
                          ),
                          decoration:
                              BoxDecoration(
                            color:
                                Colors.white,
                            borderRadius:
                                BorderRadius.circular(
                              22,
                            ),
                            border:
                                Border.all(
                              color:
                                  const Color(
                                0xFFE5EBF2,
                              ),
                            ),
                          ),
                          child:
                              const Column(
                            children: [
                              Icon(
                                Icons
                                    .search_off_rounded,
                                size:
                                    45,
                                color:
                                    Colors.blueGrey,
                              ),
                              SizedBox(
                                height:
                                    10,
                              ),
                              Text(
                                'No facilities found for this filter.',
                                textAlign:
                                    TextAlign.center,
                                style:
                                    TextStyle(
                                  color:
                                      Colors.blueGrey,
                                ),
                              ),
                            ],
                          ),
                        ),

                      // ===========================================
                      // FACILITY LIST
                      // ===========================================

                      ..._filteredFacilities
                          .map(
                        (facility) =>
                            Padding(
                          padding:
                              const EdgeInsets.only(
                            bottom: 12,
                          ),
                          child:
                              _FacilityCard(
                            facility:
                                facility,
                            onCall:
                                () {
                              _callFacility(
                                facility,
                              );
                            },
                            onMap:
                                () {
                              _openMap(
                                facility,
                              );
                            },
                            onWebsite:
                                () {
                              _openWebsite(
                                facility,
                              );
                            },
                          ),
                        ),
                      ),

                      const SizedBox(
                        height: 8,
                      ),

                      // ===========================================
                      // DATA NOTICE
                      // ===========================================

                      Container(
                        padding:
                            const EdgeInsets.all(
                          16,
                        ),
                        decoration:
                            BoxDecoration(
                          color:
                              const Color(
                            0xFFEAF4FF,
                          ),
                          borderRadius:
                              BorderRadius.circular(
                            18,
                          ),
                        ),
                        child:
                            const Row(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons
                                  .info_outline_rounded,
                              color:
                                  blue,
                            ),

                            SizedBox(
                              width:
                                  10,
                            ),

                            Expanded(
                              child:
                                  Text(
                                'Facility information comes from map data. A phone number, website, speciality or opening hours will only appear when that information is available in the source data. Verify important information before relying on it.',
                                style:
                                    TextStyle(
                                  color:
                                      Color(
                                    0xFF315C86,
                                  ),
                                  fontSize:
                                      11,
                                  height:
                                      1.45,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  // ============================================================
  // LOADING
  // ============================================================

  Widget _buildLoading() {
    return const Center(
      child: Column(
        mainAxisSize:
            MainAxisSize.min,
        children: [
          CircularProgressIndicator(),

          SizedBox(
            height: 15,
          ),

          Text(
            'Finding healthcare near you...',
            style: TextStyle(
              color:
                  Colors.blueGrey,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ERROR
  // ============================================================

  Widget _buildError() {
    const navy =
        Color(0xFF082B5C);

    const blue =
        Color(0xFF0968D8);

    final message =
        _error ??
            'Unable to find nearby healthcare.';

    return ListView(
      padding:
          const EdgeInsets.all(
        22,
      ),
      children: [
        const SizedBox(
          height: 45,
        ),

        Container(
          padding:
              const EdgeInsets.all(
            25,
          ),
          decoration:
              BoxDecoration(
            color: Colors.white,
            borderRadius:
                BorderRadius.circular(
              25,
            ),
          ),
          child: Column(
            children: [
              Container(
                width: 70,
                height: 70,
                decoration:
                    BoxDecoration(
                  color:
                      Colors.red.shade50,
                  shape:
                      BoxShape.circle,
                ),
                child: const Icon(
                  Icons
                      .location_off_rounded,
                  color:
                      Colors.red,
                  size: 35,
                ),
              ),

              const SizedBox(
                height: 18,
              ),

              const Text(
                'Location unavailable',
                style:
                    TextStyle(
                  color: navy,
                  fontSize: 21,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              const SizedBox(
                height: 9,
              ),

              Text(
                message,
                textAlign:
                    TextAlign.center,
                style:
                    const TextStyle(
                  color:
                      Colors.blueGrey,
                  fontSize: 12,
                  height: 1.5,
                ),
              ),

              const SizedBox(
                height: 20,
              ),

              SizedBox(
                width:
                    double.infinity,
                child:
                    ElevatedButton.icon(
                  onPressed:
                      _loadNearbyCare,
                  style:
                      ElevatedButton.styleFrom(
                    backgroundColor:
                        blue,
                    foregroundColor:
                        Colors.white,
                    elevation: 0,
                  ),
                  icon:
                      const Icon(
                    Icons
                        .refresh_rounded,
                  ),
                  label:
                      const Text(
                    'TRY AGAIN',
                  ),
                ),
              ),

              const SizedBox(
                height: 8,
              ),

              SizedBox(
                width:
                    double.infinity,
                child:
                    OutlinedButton.icon(
                  onPressed:
                      _openLocationSettings,
                  icon:
                      const Icon(
                    Icons
                        .location_on_outlined,
                  ),
                  label:
                      const Text(
                    'LOCATION SETTINGS',
                  ),
                ),
              ),

              SizedBox(
                width:
                    double.infinity,
                child:
                    TextButton.icon(
                  onPressed:
                      _openAppSettings,
                  icon:
                      const Icon(
                    Icons
                        .settings_outlined,
                  ),
                  label:
                      const Text(
                    'APP PERMISSIONS',
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// =============================================================
// FACILITY CARD
// =============================================================

class _FacilityCard
    extends StatelessWidget {
  final NearbyMedicalFacility facility;

  final VoidCallback onCall;
  final VoidCallback onMap;
  final VoidCallback onWebsite;

  const _FacilityCard({
    required this.facility,
    required this.onCall,
    required this.onMap,
    required this.onWebsite,
  });

  IconData get _icon {
    switch (facility.type) {
      case 'Hospital':
        return Icons
            .local_hospital_rounded;

      case 'Clinic':
        return Icons
            .medical_services_rounded;

      case 'Doctor':
        return Icons
            .person_search_rounded;

      default:
        return Icons
            .health_and_safety_rounded;
    }
  }

  String get _distance {
    if (facility.distanceKm <
        1) {
      final meters =
          (facility.distanceKm *
                  1000)
              .round();

      return '$meters m';
    }

    return '${facility.distanceKm.toStringAsFixed(1)} km';
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    const navy =
        Color(0xFF082B5C);

    const blue =
        Color(0xFF0968D8);

    return Container(
      padding:
          const EdgeInsets.all(
        17,
      ),
      decoration:
          BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(
          22,
        ),
        border: Border.all(
          color:
              const Color(
            0xFFE5EBF2,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration:
                    BoxDecoration(
                  color:
                      const Color(
                    0xFFEAF4FF,
                  ),
                  borderRadius:
                      BorderRadius.circular(
                    15,
                  ),
                ),
                child: Icon(
                  _icon,
                  color: blue,
                ),
              ),

              const SizedBox(
                width: 12,
              ),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      facility.name,
                      style:
                          const TextStyle(
                        color: navy,
                        fontSize: 16,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    const SizedBox(
                      height: 4,
                    ),

                    Wrap(
                      spacing: 6,
                      runSpacing: 5,
                      children: [
                        _SmallBadge(
                          text:
                              facility.type,
                          icon: Icons
                              .health_and_safety_outlined,
                        ),

                        _SmallBadge(
                          text:
                              _distance,
                          icon: Icons
                              .near_me_outlined,
                        ),

                        if (facility
                            .emergency)
                          const _SmallBadge(
                            text:
                                'Emergency',
                            icon: Icons
                                .emergency_outlined,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (facility.address !=
              null) ...[
            const SizedBox(
              height: 13,
            ),

            _InfoRow(
              icon:
                  Icons.location_on_outlined,
              text:
                  facility.address!,
            ),
          ],

          if (facility.phone !=
              null) ...[
            const SizedBox(
              height: 8,
            ),

            _InfoRow(
              icon:
                  Icons.phone_outlined,
              text:
                  facility.phone!,
            ),
          ],

          if (facility.speciality !=
              null) ...[
            const SizedBox(
              height: 8,
            ),

            _InfoRow(
              icon:
                  Icons.medical_information_outlined,
              text:
                  facility.speciality!,
            ),
          ],

          if (facility.openingHours !=
              null) ...[
            const SizedBox(
              height: 8,
            ),

            _InfoRow(
              icon:
                  Icons.schedule_outlined,
              text:
                  facility.openingHours!,
            ),
          ],

          const SizedBox(
            height: 15,
          ),

          Row(
            children: [
              Expanded(
                child:
                    ElevatedButton.icon(
                  onPressed:
                      facility.hasPhone
                          ? onCall
                          : null,
                  style:
                      ElevatedButton.styleFrom(
                    backgroundColor:
                        const Color(
                      0xFF0A8F5A,
                    ),
                    foregroundColor:
                        Colors.white,
                    disabledBackgroundColor:
                        Colors.grey.shade200,
                    disabledForegroundColor:
                        Colors.grey,
                    elevation: 0,
                    padding:
                        const EdgeInsets.symmetric(
                      vertical: 12,
                    ),
                  ),
                  icon:
                      const Icon(
                    Icons
                        .phone_rounded,
                    size: 18,
                  ),
                  label: Text(
                    facility.hasPhone
                        ? 'CALL'
                        : 'NO PHONE',
                    style:
                        const TextStyle(
                      fontSize: 11,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(
                width: 8,
              ),

              Expanded(
                child:
                    OutlinedButton.icon(
                  onPressed:
                      onMap,
                  style:
                      OutlinedButton.styleFrom(
                    foregroundColor:
                        blue,
                    padding:
                        const EdgeInsets.symmetric(
                      vertical: 12,
                    ),
                  ),
                  icon:
                      const Icon(
                    Icons
                        .map_outlined,
                    size: 18,
                  ),
                  label:
                      const Text(
                    'MAP',
                    style:
                        TextStyle(
                      fontSize: 11,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ),
              ),

              if (facility
                  .hasWebsite) ...[
                const SizedBox(
                  width: 8,
                ),

                IconButton(
                  tooltip:
                      'Website',
                  onPressed:
                      onWebsite,
                  style:
                      IconButton.styleFrom(
                    backgroundColor:
                        const Color(
                      0xFFEAF4FF,
                    ),
                    foregroundColor:
                        blue,
                  ),
                  icon:
                      const Icon(
                    Icons
                        .language_rounded,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// =============================================================
// SUMMARY CARD
// =============================================================

class _SummaryCard
    extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _SummaryCard({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        vertical: 14,
        horizontal: 8,
      ),
      decoration:
          BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(
          18,
        ),
        border: Border.all(
          color:
              const Color(
            0xFFE5EBF2,
          ),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color:
                const Color(
              0xFF0968D8,
            ),
            size: 21,
          ),

          const SizedBox(
            height: 5,
          ),

          Text(
            value,
            style:
                const TextStyle(
              color:
                  Color(
                0xFF082B5C,
              ),
              fontSize: 18,
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          Text(
            title,
            textAlign:
                TextAlign.center,
            style:
                const TextStyle(
              color:
                  Colors.blueGrey,
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================
// SMALL BADGE
// =============================================================

class _SmallBadge
    extends StatelessWidget {
  final String text;
  final IconData icon;

  const _SmallBadge({
    required this.text,
    required this.icon,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration:
          BoxDecoration(
        color:
            const Color(
          0xFFF0F5FA,
        ),
        borderRadius:
            BorderRadius.circular(
          20,
        ),
      ),
      child: Row(
        mainAxisSize:
            MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color:
                Colors.blueGrey,
          ),

          const SizedBox(
            width: 4,
          ),

          Text(
            text,
            style:
                const TextStyle(
              color:
                  Colors.blueGrey,
              fontSize: 9,
              fontWeight:
                  FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================
// INFO ROW
// =============================================================

class _InfoRow
    extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoRow({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 17,
          color:
              Colors.blueGrey,
        ),

        const SizedBox(
          width: 7,
        ),

        Expanded(
          child: Text(
            text,
            style:
                const TextStyle(
              color:
                  Color(
                0xFF52677C,
              ),
              fontSize: 11,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}

// =============================================================
// RADIUS OPTION
// =============================================================

class _RadiusOption
    extends StatelessWidget {
  final String title;
  final bool selected;
  final VoidCallback onTap;

  const _RadiusOption({
    required this.title,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return ListTile(
      onTap: onTap,
      shape:
          RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(
          15,
        ),
      ),
      leading: Icon(
        Icons.radar_rounded,
        color: selected
            ? const Color(
                0xFF0968D8,
              )
            : Colors.blueGrey,
      ),
      title: Text(
        title,
        style: TextStyle(
          color:
              const Color(
            0xFF082B5C,
          ),
          fontWeight: selected
              ? FontWeight.bold
              : FontWeight.normal,
        ),
      ),
      trailing: selected
          ? const Icon(
              Icons
                  .check_circle_rounded,
              color:
                  Color(
                0xFF0968D8,
              ),
            )
          : null,
    );
  }
}