import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/control_provider.dart';
import 'screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const DeviceControlApp());
}

class DeviceControlApp extends StatelessWidget {
  const DeviceControlApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ControlProvider()),
      ],
      child: MaterialApp(
        title: 'Device Control AI',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          scaffoldBackgroundColor: const Color(0xFF020617),
          colorScheme: const ColorScheme.dark(
            primary: Colors.cyan,
            secondary: Color(0xFF10B981),
            surface: Color(0xFF0F172A),
          ),
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
