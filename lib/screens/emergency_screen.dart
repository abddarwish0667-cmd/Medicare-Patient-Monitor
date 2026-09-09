import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class EmergencyScreen extends StatelessWidget {
  const EmergencyScreen({super.key});

  // ============================================================
  // CALL NUMBER
  // ============================================================

  Future<void> _callNumber(
    BuildContext context,
    String number,
  ) async {
    final uri = Uri(
      scheme: 'tel',
      path: number,
    );

    try {
      final launched = await launchUrl(uri);

      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Unable to open the phone dialer.',
            ),
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to make this call.',
          ),
        ),
      );
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    const navy = Color(0xFF082B5C);
    const blue = Color(0xFF0968D8);
    const background = Color(0xFFF5F8FC);

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Emergency Call',
          style: TextStyle(
            color: navy,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          20,
          10,
          20,
          35,
        ),
        children: [
          // =====================================================
          // HEADER
          // =====================================================

          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF9E1C1C),
                  Color(0xFFE04444),
                ],
              ),
              borderRadius: BorderRadius.circular(26),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.emergency_rounded,
                  color: Colors.white,
                  size: 46,
                ),
                SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Emergency Assistance',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        'Quick access to emergency medical and relief services in Tripoli, Lebanon.',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          const Text(
            'Emergency Services',
            style: TextStyle(
              color: navy,
              fontSize: 21,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 14),

          // =====================================================
          // RED CROSS
          // =====================================================

          _EmergencyCard(
            icon: Icons.local_hospital_rounded,
            title: 'Lebanese Red Cross',
            subtitle: 'Ambulance & medical emergency',
            number: '140',
            buttonText: 'CALL 140',
            onCall: () {
              _callNumber(
                context,
                '140',
              );
            },
          ),

          const SizedBox(height: 14),

          // =====================================================
          // EMERGENCY & RELIEF CORPS
          // =====================================================

          _EmergencyCard(
            icon: Icons.health_and_safety_rounded,
            title: 'Emergency & Relief Corps',
            subtitle: 'Tripoli emergency and relief service',
            number: '06 433 833',
            buttonText: 'CALL 06 433 833',
            onCall: () {
              _callNumber(
                context,
                '06433833',
              );
            },
          ),

          const SizedBox(height: 14),

          // =====================================================
          // MEDICAL RELIEF CENTER
          // =====================================================

          _EmergencyCard(
            icon: Icons.medical_services_rounded,
            title: 'Medical Relief Center',
            subtitle: 'Abi Samra - Tripoli',
            number: '06 430 409',
            buttonText: 'CALL 06 430 409',
            onCall: () {
              _callNumber(
                context,
                '06430409',
              );
            },
          ),

          const SizedBox(height: 24),

          // =====================================================
          // WARNING
          // =====================================================

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF4E8),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: Color(0xFFC46A00),
                ),
                SizedBox(width: 11),
                Expanded(
                  child: Text(
                    'If the patient has severe chest pain, severe breathing difficulty, loss of consciousness, heavy bleeding, or another life-threatening emergency, contact emergency services immediately.',
                    style: TextStyle(
                      color: Color(0xFF7A4A15),
                      fontSize: 12,
                      height: 1.45,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFEAF4FF),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: blue,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Medicare provides quick access to these numbers for convenience. Availability and phone numbers may change, so important emergency contact information should be verified periodically.',
                    style: TextStyle(
                      color: Color(0xFF315C86),
                      fontSize: 11,
                      height: 1.45,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================
// EMERGENCY CARD
// =============================================================

class _EmergencyCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String number;
  final String buttonText;
  final VoidCallback onCall;

  const _EmergencyCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.number,
    required this.buttonText,
    required this.onCall,
  });

  @override
  Widget build(BuildContext context) {
    const navy = Color(0xFF082B5C);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFE5EBF2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFECEC),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  icon,
                  color: const Color(0xFFD62F2F),
                  size: 28,
                ),
              ),

              const SizedBox(width: 13),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: navy,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Colors.blueGrey,
                        fontSize: 12,
                      ),
                    ),

                    const SizedBox(height: 7),

                    Text(
                      number,
                      style: const TextStyle(
                        color: Color(0xFFD62F2F),
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 17),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: onCall,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    const Color(0xFFD62F2F),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(15),
                ),
              ),
              icon: const Icon(
                Icons.phone_rounded,
              ),
              label: Text(
                buttonText,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}