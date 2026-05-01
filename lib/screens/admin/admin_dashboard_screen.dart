import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../providers/appointment_provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../login_screen.dart';
import 'admin_appointments_screen.dart';
import 'admin_manage_slots_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppointmentProvider>().loadAllAppointments();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Painel Admin'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sair',
            onPressed: () async {
              await authProvider.logout();
              if (!context.mounted) return;
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Olá, ${authProvider.user?.name ?? "Admin"}',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark,
                  ),
            ).animate().fadeIn(duration: 300.ms),
            const SizedBox(height: 8),
            Text(
              'Gerencie seus agendamentos',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppTheme.textLight,
                  ),
            ).animate().fadeIn(delay: 200.ms),
            const SizedBox(height: 24),
            Consumer<AppointmentProvider>(
              builder: (context, provider, _) {
                final total = provider.allAppointments.length;
                final today = provider.allAppointments
                    .where((a) {
                      final now = DateTime.now();
                      return a.date.year == now.year &&
                          a.date.month == now.month &&
                          a.date.day == now.day;
                    })
                    .length;
                final confirmed = provider.allAppointments
                    .where((a) => a.status == 'confirmed')
                    .length;

                return Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        icon: Icons.calendar_today,
                        label: 'Hoje',
                        value: today.toString(),
                        color: AppTheme.darkPink,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        icon: Icons.check_circle,
                        label: 'Confirmados',
                        value: confirmed.toString(),
                        color: AppTheme.success,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        icon: Icons.event_note,
                        label: 'Total',
                        value: total.toString(),
                        color: AppTheme.accentPink,
                      ),
                    ),
                  ],
                ).animate().fadeIn(delay: 400.ms);
              },
            ),
            const SizedBox(height: 32),
            Text(
              'Ações',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 16),
            _ActionCard(
              icon: Icons.list_alt,
              title: 'Agendamentos',
              subtitle: 'Visualizar e gerenciar todos os agendamentos',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AdminAppointmentsScreen(),
                  ),
                );
              },
            ).animate().fadeIn(delay: 500.ms).slideX(begin: 0.05),
            const SizedBox(height: 12),
            _ActionCard(
              icon: Icons.access_time,
              title: 'Gerenciar Horários',
              subtitle: 'Adicionar ou remover horários disponíveis',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AdminManageSlotsScreen(),
                  ),
                );
              },
            ).animate().fadeIn(delay: 600.ms).slideX(begin: 0.05),
            const SizedBox(height: 24),
            Text(
              'Próximos agendamentos',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 12),
            Consumer<AppointmentProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading) {
                  return const Center(
                    child:
                        CircularProgressIndicator(color: AppTheme.darkPink),
                  );
                }

                final upcoming = provider.allAppointments
                    .where((a) =>
                        a.date.isAfter(DateTime.now()) &&
                        a.status == 'confirmed')
                    .toList()
                  ..sort((a, b) => a.date.compareTo(b.date));

                if (upcoming.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(
                      child: Text(
                        'Nenhum agendamento próximo',
                        style: TextStyle(color: AppTheme.textLight),
                      ),
                    ),
                  );
                }

                return Column(
                  children: upcoming.take(5).map((appointment) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppTheme.lightPink,
                          child: Text(
                            appointment.userName.isNotEmpty
                                ? appointment.userName[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              color: AppTheme.darkPink,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          appointment.userName,
                          style:
                              const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          '${appointment.date.day}/${appointment.date.month} - ${appointment.timeSlot}',
                        ),
                        trailing: const Icon(Icons.chevron_right,
                            color: AppTheme.primaryPink),
                      ),
                    );
                  }).toList(),
                ).animate().fadeIn(delay: 700.ms);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: AppTheme.textLight,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: AppTheme.lightPink,
          radius: 24,
          child: Icon(icon, color: AppTheme.darkPink),
        ),
        title: Text(title,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle,
            style: const TextStyle(color: AppTheme.textLight)),
        trailing:
            const Icon(Icons.arrow_forward_ios, color: AppTheme.primaryPink),
        onTap: onTap,
      ),
    );
  }
}
