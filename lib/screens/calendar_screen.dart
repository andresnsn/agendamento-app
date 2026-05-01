import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../providers/appointment_provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import 'time_slots_screen.dart';
import 'my_appointments_screen.dart';
import 'login_screen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppointmentProvider>().loadMyAppointments();
    });
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (selectedDay.isBefore(
        DateTime.now().subtract(const Duration(days: 1)))) {
      return;
    }

    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
    });

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TimeSlotsScreen(selectedDate: selectedDay),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text('Olá, ${authProvider.user?.name ?? ""}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.list_alt),
            tooltip: 'Meus Agendamentos',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const MyAppointmentsScreen()),
              );
            },
          ),
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
              'Escolha uma data',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textDark,
                  ),
            ).animate().fadeIn(duration: 400.ms),
            const SizedBox(height: 8),
            Text(
              'Toque no dia para ver os horários disponíveis',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textLight,
                  ),
            ).animate().fadeIn(delay: 200.ms),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: TableCalendar(
                  firstDay: DateTime.now(),
                  lastDay: DateTime.now().add(const Duration(days: 90)),
                  focusedDay: _focusedDay,
                  calendarFormat: _calendarFormat,
                  locale: 'pt_BR',
                  selectedDayPredicate: (day) =>
                      isSameDay(_selectedDay, day),
                  onDaySelected: _onDaySelected,
                  onFormatChanged: (format) {
                    setState(() {
                      _calendarFormat = format;
                    });
                  },
                  onPageChanged: (focusedDay) {
                    _focusedDay = focusedDay;
                  },
                  calendarStyle: CalendarStyle(
                    todayDecoration: BoxDecoration(
                      color: AppTheme.primaryPink.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                    selectedDecoration: const BoxDecoration(
                      color: AppTheme.darkPink,
                      shape: BoxShape.circle,
                    ),
                    weekendTextStyle:
                        const TextStyle(color: AppTheme.accentPink),
                    outsideDaysVisible: false,
                  ),
                  headerStyle: HeaderStyle(
                    formatButtonDecoration: BoxDecoration(
                      border: Border.all(color: AppTheme.darkPink),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    formatButtonTextStyle:
                        const TextStyle(color: AppTheme.darkPink),
                    titleCentered: true,
                    titleTextStyle: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textDark,
                    ),
                    leftChevronIcon: const Icon(
                      Icons.chevron_left,
                      color: AppTheme.darkPink,
                    ),
                    rightChevronIcon: const Icon(
                      Icons.chevron_right,
                      color: AppTheme.darkPink,
                    ),
                  ),
                  daysOfWeekStyle: const DaysOfWeekStyle(
                    weekdayStyle: TextStyle(
                        color: AppTheme.textDark,
                        fontWeight: FontWeight.w600),
                    weekendStyle: TextStyle(
                        color: AppTheme.accentPink,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.05),
            const SizedBox(height: 24),
            Consumer<AppointmentProvider>(
              builder: (context, provider, _) {
                if (provider.appointments.isEmpty) {
                  return const SizedBox.shrink();
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Próximos agendamentos',
                      style:
                          Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                    ),
                    const SizedBox(height: 12),
                    ...provider.appointments
                        .where((a) =>
                            a.date.isAfter(DateTime.now()) &&
                            a.status == 'confirmed')
                        .take(3)
                        .map(
                          (appointment) => Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: const CircleAvatar(
                                backgroundColor: AppTheme.lightPink,
                                child: Icon(Icons.calendar_today,
                                    color: AppTheme.darkPink),
                              ),
                              title: Text(
                                '${appointment.date.day}/${appointment.date.month}/${appointment.date.year}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600),
                              ),
                              subtitle: Text(appointment.timeSlot),
                              trailing: Chip(
                                label: const Text('Confirmado',
                                    style: TextStyle(
                                        fontSize: 12, color: Colors.white)),
                                backgroundColor: AppTheme.success,
                              ),
                            ),
                          ),
                        ),
                  ],
                ).animate().fadeIn(delay: 600.ms);
              },
            ),
          ],
        ),
      ),
    );
  }
}
