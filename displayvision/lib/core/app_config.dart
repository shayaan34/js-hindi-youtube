/// Global build-time configuration for DisplayVision.
class AppConfig {
  AppConfig._();

  /// When false the app runs entirely in demo mode: mock authentication,
  /// in-memory data and simulated AI. Flip to true after running
  /// `flutterfire configure` (which generates lib/firebase_options.dart)
  /// to use Firebase Auth, Firestore and Firebase Storage.
  static const bool useFirebase = false;

  /// Which vision backend the AI service should call when a real API key
  /// is supplied. Both return structured JSON zone detections.
  static const AiVisionBackend visionBackend = AiVisionBackend.geminiVision;

  /// Supply via --dart-define=AI_API_KEY=... Never commit real keys.
  static const String aiApiKey = String.fromEnvironment('AI_API_KEY');

  static const String companyName = 'DisplayVision Media Pvt. Ltd.';
  static const double gstRate = 0.18;
  static const String currencySymbol = '₹';
}

enum AiVisionBackend { openAiVision, geminiVision }
