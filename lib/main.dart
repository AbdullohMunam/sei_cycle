import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'widgets/responsive_shell.dart';

void main() {
  runApp(const SeiCycleApp());
}

class SeiCycleApp extends StatelessWidget {
  const SeiCycleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SeiCycle – Smart Integrated Farming',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const ResponsiveShell(),
    );
  }
}
