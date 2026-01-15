import 'package:flutter/material.dart';
import 'package:flutter_gap/flutter_gap.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iris_designer/Core/Services/hive_service.dart';
import 'package:iris_designer/Features/ONBOARDING/Domain/entities/client_session.dart';

class SessionHistoryDialog extends StatelessWidget {
  const SessionHistoryDialog({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. Fetch valid sessions
    final sessions = HiveService.getActiveSessions();

    return Dialog(
      backgroundColor: const Color(0xFF1E293B), // Matches your card/dialog theme
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        width: 950, // Nice wide layout for the table
        height: 600,
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- HEADER ---
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blueAccent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.history,
                      color: Colors.blueAccent, size: 28),
                ),
                const Gap(16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Session History",
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      "Active sessions from the last 24 hours",
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.white54,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.white38),
                  hoverColor: Colors.white10,
                ),
              ],
            ),

            const Gap(24),
            const Divider(color: Colors.white10, height: 1),
            const Gap(24),

            // --- TABLE CONTENT ---
            Expanded(
              child: sessions.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.hourglass_empty_rounded,
                              size: 64, color: Colors.white10),
                          const Gap(16),
                          Text(
                            "No active sessions found.",
                            style: GoogleFonts.poppins(
                                color: Colors.white38, fontSize: 16),
                          ),
                        ],
                      ),
                    )
                  : Theme(
                      // Override table theme for this widget
                      data: Theme.of(context).copyWith(
                        dividerColor: Colors.white10,
                        dataTableTheme: DataTableThemeData(
                          // ✅ CHANGED: Set header background to transparent
                          headingRowColor:
                              WidgetStateProperty.all(Colors.transparent),
                          dataRowColor:
                              WidgetStateProperty.resolveWith((states) {
                            if (states.contains(WidgetState.hovered)) {
                              return Colors.white.withOpacity(0.05);
                            }
                            return Colors.transparent;
                          }),
                        ),
                      ),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.vertical,
                        child: SizedBox(
                          width: double.infinity,
                          child: DataTable(
                            columnSpacing: 24,
                            horizontalMargin: 24,
                            headingRowHeight: 50,
                            dataRowMinHeight: 60,
                            dataRowMaxHeight: 60,
                            headingTextStyle: GoogleFonts.poppins(
                              color: Colors.white70,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                              letterSpacing: 1.0,
                            ),
                            dataTextStyle: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                            columns: const [
                              DataColumn(label: Text("CLIENT")),
                              DataColumn(label: Text("EMAIL")),
                              DataColumn(label: Text("COUNTRY")),
                              DataColumn(label: Center(child: Text("UPLOADS"))),
                              DataColumn(label: Center(child: Text("ARTWORKS"))),
                              DataColumn(label: Text("EXPIRES IN")),
                            ],
                            rows: sessions.map((session) {
                              final expiryTime = session.createdAt
                                  .add(const Duration(hours: 24));
                              final remaining =
                                  expiryTime.difference(DateTime.now());

                              final timeString = remaining.isNegative
                                  ? "Expired"
                                  : "${remaining.inHours}h ${remaining.inMinutes % 60}m";

                              return DataRow(
                                cells: [
                                  // Client
                                  DataCell(
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.person_outline,
                                            size: 16, color: Colors.white38),
                                        const Gap(12),
                                        Text(session.clientName,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.w500)),
                                      ],
                                    ),
                                  ),
                                  // Email
                                  DataCell(Text(session.email,
                                      style: const TextStyle(
                                          color: Colors.white70, fontSize: 13))),
                                  // Country
                                  DataCell(Text(session.country,
                                      style: const TextStyle(
                                          color: Colors.white70, fontSize: 13))),

                                  // Photos Badge
                                  DataCell(
                                    Center(
                                      child: Container(
                                        width: 40,
                                        height: 28,
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          color: Colors.blueAccent
                                              .withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          border: Border.all(
                                              color: Colors.blueAccent
                                                  .withOpacity(0.3)),
                                        ),
                                        child: Text(
                                          "${session.importedPhotos.length}",
                                          style: const TextStyle(
                                              color: Colors.blueAccent,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12),
                                        ),
                                      ),
                                    ),
                                  ),

                                  // Arts Badge
                                  DataCell(
                                    Center(
                                      child: Container(
                                        width: 40,
                                        height: 28,
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          color: Colors.pinkAccent
                                              .withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          border: Border.all(
                                              color: Colors.pinkAccent
                                                  .withOpacity(0.3)),
                                        ),
                                        child: Text(
                                          "${session.generatedArt.length}",
                                          style: const TextStyle(
                                              color: Colors.pinkAccent,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12),
                                        ),
                                      ),
                                    ),
                                  ),

                                  // Timer
                                  DataCell(
                                    Row(
                                      children: [
                                        const Icon(Icons.timer_outlined,
                                            size: 14,
                                            color: Colors.orangeAccent),
                                        const Gap(8),
                                        Text(
                                          timeString,
                                          style: GoogleFonts.poppins(
                                              color: Colors.orangeAccent,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}