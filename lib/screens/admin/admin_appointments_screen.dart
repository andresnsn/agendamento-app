import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../providers/appointment_provider.dart';
import '../../theme/app_theme.dart';

class AdminAppointmentsScreen extends StatefulWidget {
  const AdminAppointmentsScreen({super.key});

  @override
  State<AdminAppointmentsScreen> createState() =>
      _AdminAppointmentsScreenState();
}

class _AdminAppointmentsScreenState extends State<AdminAppointmentsScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppointmentProvider>().loadAllAppointments();
    });
  }

  void _filterByDate(DateTime date) {
    setState(() {
      _selectedDay = date;
      _focusedDay = date;
    });
    final dateStr =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    context.read<AppointmentProvider>().loadAllAppointments(date: dateStr);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agendamentos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() => _selectedDay = null);
              context.read<AppointmentProvider>().loadAllAppointments();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Card(
            margin: const EdgeInsets.all(8),
            child: TableCalendar(
              firstDay: DateTime.now().subtract(const Duration(days: 365)),
              lastDay: DateTime.now().add(const Duration(days: 365)),
              focusedDay: _focusedDay,
              calendarFormat: CalendarFormat.twoWeeks,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              onDaySelected: (selected, focused) => _filterByDate(selected),
              onPageChanged: (focusedDay) => _focusedDay = focusedDay,
              calendarStyle: CalendarStyle(
                todayDecoration: BoxDecoration(
                  color: AppTheme.primaryPink.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                selectedDecoration: const BoxDecoration(
                  color: AppTheme.darkPink,
                  shape: BoxShape.circle,
                ),
              ),
              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
              ),
            ),
          ),
          if (_selectedDay != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Icon(Icons.filter_list,
                      size: 16, color: AppTheme.textLight),
                  const SizedBox(width: 8),
                  Text(
                    'Filtrando: ${_selectedDay!.day}/${_selectedDay!.month}/${_selectedDay!.year}',
                    style: const TextStyle(color: AppTheme.textLight),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      setState(() => _selectedDay = null);
                      context
                          .read<AppointmentProvider>()
                          .loadAllAppointments();
                    },
                    child: const Text('Limpar filtro'),
                  ),
                ],
              ),
            ),
          Expanded(
            child: Consumer<AppointmentProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading) {
                  return const Center(
                    child:
                        CircularProgressIndicator(color: AppTheme.darkPink),
                  );
                }

                if (provider.allAppointments.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.event_busy,
                            size: 64,
                            color:
                                AppTheme.primaryPink.withValues(alpha: 0.5)),
                        const SizedBox(height: 16),
                        const Text(
                          'Nenhum agendamento encontrado',
                          style: TextStyle(
                              color: AppTheme.textLight, fontSize: 16),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: provider.allAppointments.length,
                  itemBuilder: (context, index) {
                    final appointment = provider.allAppointments[index];
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
                          '${appointment.date.day}/${appointment.date.month}/${appointment.date.year} - ${appointment.timeSlot}',
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) async {
                            if (value == 'delete') {
                              _showDeleteDialog(context, appointment.id);
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete, color: AppTheme.error),
                                  SizedBox(width: 8),
                                  Text('Excluir'),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                        .animate()
                        .fadeIn(delay: (50 * index).ms)
                        .slideX(begin: 0.03);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, String appointmentId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Excluir Agendamento'),
        content:
            const Text('Tem certeza que deseja excluir este agendamento?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await context
                  .read<AppointmentProvider>()
                  .adminDeleteAppointment(appointmentId);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }
}
