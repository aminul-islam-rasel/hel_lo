import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Enable Edge-to-Edge System Bars
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
    ),
  );

  bool firebaseInitialized = false;
  String? initializationError;

  try {
    await Firebase.initializeApp();
    
    // Enable offline persistence for Firestore
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );

    await NotificationService.initialize();
    firebaseInitialized = true;
  } catch (e) {
    debugPrint('Firebase initialization error: $e');
    initializationError = e.toString();
  }

  runApp(
    ProviderScope(
      child: WhatsAppApp(
        firebaseInitialized: firebaseInitialized,
        initializationError: initializationError,
      ),
    ),
  );
}

class WhatsAppApp extends ConsumerWidget {
  final bool firebaseInitialized;
  final String? initializationError;

  const WhatsAppApp({
    super.key,
    this.firebaseInitialized = true,
    this.initializationError,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!firebaseInitialized) {
      return MaterialApp(
        title: 'Hel Lo - Error',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text(
                    'Initialization Failed',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Please ensure google-services.json (Android) or GoogleService-Info.plist (iOS) is configured correctly.\n\nError: ${initializationError ?? "Unknown error"}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      main();
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry Initialization'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Hel Lo',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}
