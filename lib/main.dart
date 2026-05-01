import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/appointment_provider.dart';
import 'screens/login_screen.dart';
import 'services/api_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('pt_BR', null);
  runApp(const AgendamentoApp());
}

class AgendamentoApp extends StatelessWidget {
  const AgendamentoApp({super.key});

  @override
  Widget build(BuildContext context) {
    final apiService = ApiService();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider(apiService)),
        ChangeNotifierProvider(
            create: (_) => AppointmentProvider(apiService)),
      ],
      child: MaterialApp(
        title: 'Agendamento',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.theme,
        home: const LoginScreen(),
      ),
    );
  }
}
