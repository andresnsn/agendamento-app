import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../providers/appointment_provider.dart';
import '../../theme/app_theme.dart';

class AdminManageSlotsScreen extends StatefulWidget {
  const AdminManageSlotsScreen({super.key});

  @override
  State<AdminManageSlotsScreen> createState() => _AdminManageSlotsScreenState();
}

class _AdminManageSlotsScreenState extends State<AdminManageSlotsScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppointmentProvider>().loadTimeSlots(_selectedDay);
    });
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
    });
    context.read<AppointmentProvider>().loadTimeSlots(selectedDay);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gerenciar Horários'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddSlotDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Novo Horário'),
      ),
      body: Column(
        children: [
          Card(
            margin: const EdgeInsets.all(8),
            child: TableCalendar(
              firstDay: DateTime.now(),
              lastDay: DateTime.now().add(const Duration(days: 365)),
              focusedDay: _focusedDay,
              calendarFormat: CalendarFormat.week,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              onDaySelected: _onDaySelected,
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
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.access_time, color: AppTheme.darkPink),
                const SizedBox(width: 8),
                Text(
                  'Horários para ${_selectedDay.day}/${_selectedDay.month}/${_selectedDay.year}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
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

                if (provider.timeSlots.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.schedule,
                            size: 64,
                            color:
                                AppTheme.primaryPink.withValues(alpha: 0.5)),
                        const SizedBox(height: 16),
                        const Text(
                          'Nenhum horário cadastrado\npara esta data',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: AppTheme.textLight, fontSize: 16),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () => _showAddSlotDialog(context),
                          icon: const Icon(Icons.add),
                          label: const Text('Adicionar Horário'),
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
                          style:
                              const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          slot.isAvailable ? 'Disponível' : 'Ocupado',
                          style: TextStyle(
                            color: slot.isAvailable
                                ? AppTheme.success
                                : AppTheme.error,
                          ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline,
                              color: AppTheme.error),
                          onPressed: () =>
                              _showDeleteDialog(context, slot.id),
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

  void _showAddSlotDialog(BuildContext context) {
    final timeController = TextEditingController();
    TimeOfDay selectedTime = TimeOfDay.now();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Adicionar Horário'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Data: ${_selectedDay.day}/${_selectedDay.month}/${_selectedDay.year}',
              style: const TextStyle(color: AppTheme.textLight),
            ),
            const SizedBox(height: 16),
            StatefulBuilder(
              builder: (context, setDialogState) {
                timeController.text =
                    '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}';
                return TextFormField(
                  controller: timeController,
                  readOnly: true,
                  decoration: const InputDecoration(
                    hintText: 'Selecione o horário',
                    prefixIcon: Icon(Icons.access_time),
                  ),
                  onTap: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: selectedTime,
                    );
                    if (time != null) {
                      setDialogState(() {
                        selectedTime = time;
                      });
                    }
                  },
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              final timeStr =
                  '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}';
              await context
                  .read<AppointmentProvider>()
                  .adminCreateTimeSlot(_selectedDay, timeStr);
            },
            child: const Text('Adicionar'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, String slotId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Excluir Horário'),
        content: const Text('Tem certeza que deseja excluir este horário?'),
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
                  .adminDeleteTimeSlot(slotId);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }
}
