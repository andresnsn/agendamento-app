import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../providers/appointment_provider.dart';
import '../theme/app_theme.dart';
import 'booking_confirmation_screen.dart';

class TimeSlotsScreen extends StatefulWidget {
  final DateTime selectedDate;

  const TimeSlotsScreen({super.key, required this.selectedDate});

  @override
  State<TimeSlotsScreen> createState() => _TimeSlotsScreenState();
}

class _TimeSlotsScreenState extends State<TimeSlotsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppointmentProvider>().loadTimeSlots(widget.selectedDate);
    });
  }

  String _formatDate(DateTime date) {
    const months = [
      'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
      'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro'
    ];
    const weekdays = [
      'Segunda-feira', 'Terça-feira', 'Quarta-feira',
      'Quinta-feira', 'Sexta-feira', 'Sábado', 'Domingo'
    ];
    return '${weekdays[date.weekday - 1]}, ${date.day} de ${months[date.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Horários Disponíveis'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.darkPink,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: Column(
              children: [
                const Icon(Icons.calendar_today, color: Colors.white, size: 32),
                const SizedBox(height: 8),
                Text(
                  _formatDate(widget.selectedDate),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ).animate().fadeIn(duration: 300.ms),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Selecione um horário',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Consumer<AppointmentProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppTheme.darkPink),
                  );
                }

                if (provider.error != null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline,
                            size: 48, color: AppTheme.error),
                        const SizedBox(height: 16),
                        Text(provider.error!),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () =>
                              provider.loadTimeSlots(widget.selectedDate),
                          child: const Text('Tentar novamente'),
                        ),
                      ],
                    ),
                  );
                }

                if (provider.timeSlots.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.event_busy,
                            size: 64,
                            color: AppTheme.primaryPink.withValues(alpha: 0.5)),
                        const SizedBox(height: 16),
                        const Text(
                          'Nenhum horário disponível\npara esta data',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppTheme.textLight,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: provider.timeSlots.length,
                  itemBuilder: (context, index) {
                    final slot = provider.timeSlots[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: slot.isAvailable
                              ? AppTheme.lightPink
                              : Colors.grey[200],
                          child: Icon(
                            Icons.access_time,
                            color: slot.isAvailable
                                ? AppTheme.darkPink
                                : Colors.grey,
                          ),
                        ),
                        title: Text(
                          slot.time,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: slot.isAvailable
                                ? AppTheme.textDark
                                : Colors.grey,
                          ),
                        ),
                        subtitle: Text(
                          slot.isAvailable ? 'Disponível' : 'Indisponível',
                          style: TextStyle(
                            color: slot.isAvailable
                                ? AppTheme.success
                                : Colors.grey,
                          ),
                        ),
                        trailing: slot.isAvailable
                            ? ElevatedButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          BookingConfirmationScreen(
                                        date: widget.selectedDate,
                                        timeSlot: slot,
                                      ),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 8),
                                ),
                                child: const Text('Agendar'),
                              )
                            : const Chip(
                                label: Text('Ocupado',
                                    style: TextStyle(fontSize: 12)),
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
          ),
        ],
      ),
    );
  }
}
