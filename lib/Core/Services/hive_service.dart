import 'package:hive_flutter/hive_flutter.dart';
import 'package:iris_designer/Features/ONBOARDING/Domain/entities/client_session.dart';

class HiveService {
  static const String _boxName = 'sessions_box';

  // 1. Initialize Hive (Call this in main.dart)
  static Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(ClientSessionAdapter());
    await Hive.openBox<ClientSession>(_boxName);
  }

  // 2. Save or Update Session
  static Future<void> saveSession(ClientSession session) async {
    final box = Hive.box<ClientSession>(_boxName);
    await box.put(session.id, session);
  }

  // 3. Get Active Sessions (Auto-delete expired ones)
  static List<ClientSession> getActiveSessions() {
    final box = Hive.box<ClientSession>(_boxName);
    final now = DateTime.now();
    final List<String> keysToDelete = [];
    final List<ClientSession> activeSessions = [];

    for (var key in box.keys) {
      final session = box.get(key);
      if (session != null) {
        // Calculate difference
        final difference = now.difference(session.createdAt);
        
        if (difference.inHours >= 24) {
          // ❌ Expired: Mark for deletion
          keysToDelete.add(key.toString());
        } else {
          // ✅ Active: Add to list
          activeSessions.add(session);
        }
      }
    }

    // Clean up expired data
    if (keysToDelete.isNotEmpty) {
      box.deleteAll(keysToDelete);
    }

    return activeSessions;
  }
  
  // 4. Clear All (Optional, for debugging)
  static Future<void> clearAll() async {
    final box = Hive.box<ClientSession>(_boxName);
    await box.clear();
  }
}