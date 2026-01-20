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
  
  // 4. Get Session by ID
  static ClientSession? getSessionById(String sessionId) {
    final box = Hive.box<ClientSession>(_boxName);
    return box.get(sessionId);
  }

  // 5. Update Session with Raw Images (imported photos)
  static Future<void> updateSessionImages(String sessionId, List<String> imagePaths) async {
    final box = Hive.box<ClientSession>(_boxName);
    final session = box.get(sessionId);
    
    if (session != null) {
      // Create updated session with new image paths
      final updatedSession = session.copyWith(
        importedPhotos: imagePaths,
      );
      await box.put(sessionId, updatedSession);
    }
  }

  // 6. Update Session with Generated Art (edited/final images)
  static Future<void> updateSessionGeneratedArt(String sessionId, List<String> artPaths) async {
    final box = Hive.box<ClientSession>(_boxName);
    final session = box.get(sessionId);
    
    if (session != null) {
      // Create updated session with new art paths
      final updatedSession = session.copyWith(
        generatedArt: artPaths,
      );
      await box.put(sessionId, updatedSession);
    }
  }

  // 7. Add Single Image to Session (for incremental updates)
  static Future<void> addImageToSession(String sessionId, String imagePath) async {
    final box = Hive.box<ClientSession>(_boxName);
    final session = box.get(sessionId);
    
    if (session != null) {
      // Avoid duplicates
      final updatedPhotos = List<String>.from(session.importedPhotos);
      if (!updatedPhotos.contains(imagePath)) {
        updatedPhotos.add(imagePath);
        final updatedSession = session.copyWith(importedPhotos: updatedPhotos);
        await box.put(sessionId, updatedSession);
      }
    }
  }

  // 8. Remove Single Image from Session
  static Future<void> removeImageFromSession(String sessionId, String imagePath) async {
    final box = Hive.box<ClientSession>(_boxName);
    final session = box.get(sessionId);
    
    if (session != null) {
      final updatedPhotos = List<String>.from(session.importedPhotos)
        ..remove(imagePath);
      final updatedSession = session.copyWith(importedPhotos: updatedPhotos);
      await box.put(sessionId, updatedSession);
    }
  }
  
  // 9. Clear All (Optional, for debugging)
  static Future<void> clearAll() async {
    final box = Hive.box<ClientSession>(_boxName);
    await box.clear();
  }
}
