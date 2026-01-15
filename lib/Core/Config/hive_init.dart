import 'package:hive_flutter/hive_flutter.dart';
// ✅ Import your Entity to register the generated Adapter
import 'package:iris_designer/Features/ONBOARDING/Domain/entities/client_session.dart';

Future<void> initHive() async {
  // 1. Initialize Hive for Flutter (handles directory paths automatically)
  await Hive.initFlutter();

  // 2. Register Adapters
  // This allows Hive to understand your custom 'ClientSession' class.
  // Note: If you have more entities later, register them here.
  Hive.registerAdapter(ClientSessionAdapter());

  // 3. Open Boxes (Like SQL Tables)
  // Opening it here ensures it is ready before the app UI builds.
  await Hive.openBox<ClientSession>('sessions_box');
}