import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../models/time_slot_model.dart';
import '../providers/appointment_provider.dart';
import '../theme/app_theme.dart';

class BookingConfirmationScreen extends StatelessWidget {
  final DateTime date;
  final TimeSlotModel timeSlot;

  const BookingConfirmationScreen({
    super.key,
    required this.date,
    required this.timeSlot,
  });

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirmar Agendamento'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Spacer(),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Icon(
                      Icons.event_available,
                      size: 64,
                      color: AppTheme.darkPink,
                    ).animate().scale(duration: 400.ms),
                    const SizedBox(height: 16),
                    Text(
                      'Confirme seu agendamento',
                      style:
                          Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.darkPink,
                              ),
                    ),
                    const SizedBox(height: 24),
                    _InfoRow(
                      icon: Icons.calendar_today,
                      label: 'Data',
                      value: _formatDate(date),
                    ),
                    const Divider(height: 24),
                    _InfoRow(
                      icon: Icons.access_time,
                      label: 'Horário',
                      value: timeSlot.time,
                    ),
                  ],
                ),
              ),
            ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.05),
            const Spacer(),
            Consumer<AppointmentProvider>(
              builder: (context, provider, _) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (provider.error != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Text(
                          provider.error!,
                          style: const TextStyle(color: AppTheme.error),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ElevatedButton.icon(
                      onPressed: provider.isLoading
                          ? null
                          : () async {
                              final success = await provider.bookAppointment(
                                  date, timeSlot.id);
                              if (success && context.mounted) {
                                _showSuccessDialog(context);
                              }
                            },
                      icon: provider.isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.check),
                      label: Text(
                          provider.isLoading ? 'Agendando...' : 'Confirmar'),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Voltar'),
                    ),
                  ],
                );
              },
            ).animate().fadeIn(delay: 400.ms),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _showSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, size: 64, color: AppTheme.success)
                .animate()
                .scale(duration: 400.ms),
            const SizedBox(height: 16),
            const Text(
              'Agendamento Confirmado!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Você receberá uma confirmação por e-mail.',
              style: TextStyle(color: AppTheme.textLight),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text('Voltar ao Calendário'),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          backgroundColor: AppTheme.lightPink,
          radius: 20,
          child: Icon(icon, color: AppTheme.darkPink, size: 20),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: AppTheme.textLight,
                fontSize: 14,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.textDark,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
