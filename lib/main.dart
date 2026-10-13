import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = const bool.fromEnvironment(
    'ALLOW_RUNTIME_FONTS',
    defaultValue: !kReleaseMode,
  );
  runApp(const EyInvoiceMobileApp());
}
