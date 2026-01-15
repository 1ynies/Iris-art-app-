import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class ClientInfoCard extends StatelessWidget {
  final String name;
  final String email;
  final String location;

  const ClientInfoCard({
    super.key,
    required this.name,
    required this.email,
    required this.location,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1C232D), // Matches the dark card background
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.05),
        ), // Subtle border
      ),
      child: Row(
        children: [
          // 1. Avatar Section
          Container(
            width: 60,
            height: 60,
            decoration: const BoxDecoration(
              color: Color(0xFF2A3441), // Lighter grey-blue circle
              shape: BoxShape.circle,
            ),
            // Padding inside ensures the SVG isn't too big
            padding: const EdgeInsets.all(12),
            child: SvgPicture.asset(
              "assets/Icons/user-mini.svg",
              // Using colorFilter is the modern way to color SVGs
              colorFilter: const ColorFilter.mode(
                Color(0xFF94A3B8), // Light grey icon color
                BlendMode.srcIn,
              ),
            ),
          ),
          const SizedBox(width: 16),

          // 2. Client Info Section
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'CLIENT',
                  style: TextStyle(
                    color: Color(0xFF64748B), // Muted slate text
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    // letterSpacing: 1.0, // Makes the all-caps look cleaner
                  ),
                ),
                const SizedBox(height: 4),
                //! ================  NAME  ===================
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  email,
                  style: const TextStyle(
                    color: Color(0xFF94A3B8), // Lighter grey for readability
                    fontSize: 17,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // 3. Location Section
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'LOCATION',
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                 
                  SvgPicture.asset(
                    'assets/Icons/globe-solid.svg',
                    width: 25,
                    height: 25,
                    color: Color(0xFF3B82F6),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    location,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
