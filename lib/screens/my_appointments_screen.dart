import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../providers/appointment_provider.dart';
import '../theme/app_theme.dart';

class MyAppointmentsScreen extends StatefulWidget {
  const MyAppointmentsScreen({super.key});

  @override
  State<MyAppointmentsScreen> createState() => _MyAppointmentsScreenState();
}

class _MyAppointmentsScreenState extends State<MyAppointmentsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppointmentProvider>().loadMyAppointments();
    });
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'confirmed':
        return AppTheme.success;
      case 'cancelled':
        return AppTheme.error;
      default:
        return AppTheme.textLight;
    }
  }

  String _statusText(String status) {
    switch (status) {
      case 'confirmed':
        return 'Confirmado';
      case 'cancelled':
        return 'Cancelado';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meus Agendamentos'),
      ),
      body: Consumer<AppointmentProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.darkPink),
            );
          }

          if (provider.appointments.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event_note,
                      size: 64,
                      color: AppTheme.primaryPink.withValues(alpha: 0.5)),
                  const SizedBox(height: 16),
                  const Text(
                    'Nenhum agendamento\nrealizado ainda',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppTheme.textLight, fontSize: 16),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.appointments.length,
            itemBuilder: (context, index) {
              final appointment = provider.appointments[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: AppTheme.lightPink,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              appointment.date.day.toString(),
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.darkPink,
                              ),
                            ),
                            Text(
                              '${appointment.date.month}/${appointment.date.year.toString().substring(2)}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppTheme.accentPink,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              appointment.timeSlot,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Chip(
                              label: Text(
                                _statusText(appointment.status),
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 12),
                              ),
                              backgroundColor:
                                  _statusColor(appointment.status),
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                              visualDensity: VisualDensity.compact,
                            ),
                          ],
                        ),
                      ),
                      if (appointment.status == 'confirmed')
                        IconButton(
                          icon: const Icon(Icons.cancel_outlined,
                              color: AppTheme.error),
                          tooltip: 'Cancelar',
                          onPressed: () =>
                              _showCancelDialog(context, appointment.id),
                        ),
                    ],
                  ),
                ),
              )
                  .animate()
                  .fadeIn(delay: (100 * index).ms)
                  .slideX(begin: 0.05);
            },
          );
        },
      ),
    );
  }

  void _showCancelDialog(BuildContext context, String appointmentId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Cancelar Agendamento'),
        content:
            const Text('Tem certeza que deseja cancelar este agendamento?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Não'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await context
                  .read<AppointmentProvider>()
                  .cancelAppointment(appointmentId);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('Sim, cancelar'),
          ),
        ],
      ),
    );
  }
}
