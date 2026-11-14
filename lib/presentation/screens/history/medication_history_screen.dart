import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/util/csv_exporter.dart';
import '../../../core/util/dose_statistics.dart';
import '../../../data/models/medication_log.dart';
import '../../../state/app_state_provider.dart';
import '../../widgets/profile_selector_widget.dart';
import '../../widgets/timeline_item_widget.dart';

class MedicationHistoryScreen extends ConsumerStatefulWidget {
  const MedicationHistoryScreen({super.key});

  @override
  ConsumerState<MedicationHistoryScreen> createState() =>
      _MedicationHistoryScreenState();
}

class _MedicationHistoryScreenState
    extends ConsumerState<MedicationHistoryScreen> {
  DateTime _selectedDate = DateTime.now();
  String _statusFilter = 'all';
  final String _medicineFilter = 'all';

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final appState = ref.watch(appStateProvider);
    final logs = ref.watch(filteredLogsProvider);

    final dateFiltered = logs.where((l) {
      final isSameDay =
          l.scheduledDateTime.year == _selectedDate.year &&
          l.scheduledDateTime.month == _selectedDate.month &&
          l.scheduledDateTime.day == _selectedDate.day;

      final matchesMed =
          _medicineFilter == 'all' || l.medicineId == _medicineFilter;

      final matchesStatus =
          _statusFilter == 'all' || l.status.name == _statusFilter;

      return isSameDay && matchesMed && matchesStatus;
    }).toList();

    dateFiltered.sort(
      (a, b) => b.scheduledDateTime.compareTo(a.scheduledDateTime),
    );

    final stats = DoseStatistics.calculate(logs);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          loc?.translate('medicationHistory') ?? 'Medication History',
        ),
        actions: [
          IconButton(
            tooltip: 'Export CSV Report',
            icon: const Icon(Icons.file_download_outlined),
            onPressed: () => _exportCsv(context, logs, appState.members),
          ),
          IconButton(
            tooltip: 'Pick Date',
            icon: const Icon(Icons.calendar_month_rounded),
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime(2020),
                lastDate: DateTime(2030),
              );
              if (picked != null) {
                setState(() {
                  _selectedDate = picked;
                });
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: appState.isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, Color(0xFF055854)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              width: 56,
                              height: 56,
                              child: CircularProgressIndicator(
                                value: stats.adherencePercentage / 100,
                                strokeWidth: 6,
                                backgroundColor: Colors.white.withAlpha(50),
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            ),
                            Text(
                              '${stats.adherencePercentage}%',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                loc?.translate('adherenceRate') ??
                                    'Compliance Adherence Rate',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${stats.takenCount} Taken • ${stats.pendingCount} Pending • ${stats.missedCount} Missed',
                                style: TextStyle(
                                  color: Colors.white.withAlpha(220),
                                  fontSize: 12,
                                ),
                              ),
                              if (stats.overdueCount > 0)
                                Text(
                                  '${stats.overdueCount} dose(s) overdue',
                                  style: const TextStyle(
                                    color: AppColors.warningContainer,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const ProfileSelectorWidget(),
                  const SizedBox(height: 6),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.event_rounded,
                              size: 16,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              DateFormat('EEE, dd MMM yyyy')
                                  .format(_selectedDate),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            TextButton(
                              onPressed: () => setState(
                                () => _selectedDate = DateTime.now(),
                              ),
                              child: const Text(
                                'Today',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                            TextButton(
                              onPressed: () => setState(
                                () => _selectedDate = DateTime.now().subtract(
                                  const Duration(days: 1),
                                ),
                              ),
                              child: const Text(
                                'Yesterday',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    child: Row(
                      children: [
                        ChoiceChip(
                          label: const Text('All Status'),
                          selected: _statusFilter == 'all',
                          onSelected: (_) =>
                              setState(() => _statusFilter = 'all'),
                        ),
                        const SizedBox(width: 6),
                        ChoiceChip(
                          label: Text(
                            loc?.translate('takenSummary') ?? 'Taken',
                          ),
                          selected: _statusFilter == 'taken',
                          onSelected: (_) =>
                              setState(() => _statusFilter = 'taken'),
                        ),
                        const SizedBox(width: 6),
                        ChoiceChip(
                          label: Text(
                            loc?.translate('pendingSummary') ?? 'Pending',
                          ),
                          selected: _statusFilter == 'pending',
                          onSelected: (_) =>
                              setState(() => _statusFilter = 'pending'),
                        ),
                        const SizedBox(width: 6),
                        ChoiceChip(
                          label: Text(
                            loc?.translate('missedSummary') ?? 'Missed',
                          ),
                          selected: _statusFilter == 'missed',
                          onSelected: (_) =>
                              setState(() => _statusFilter = 'missed'),
                        ),
                        const SizedBox(width: 6),
                        ChoiceChip(
                          label: const Text('Skipped'),
                          selected: _statusFilter == 'skipped',
                          onSelected: (_) =>
                              setState(() => _statusFilter = 'skipped'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  Expanded(
                    child: dateFiltered.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.history_toggle_off_rounded,
                                  size: 64,
                                  color: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.color,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  loc?.translate('noHistoryLogs') ?? 'No medication history logs found for this filter.',
                                  style: TextStyle(
                                    color: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.color,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: dateFiltered.length,
                            itemBuilder: (context, index) {
                              final log = dateFiltered[index];
                              return TimelineItemWidget(
                                log: log,
                                isLast: index == dateFiltered.length - 1,
                              );
                            },
                          ),
                  ),
                ],
              ),
      ),
    );
  }

  void _exportCsv(
    BuildContext context,
    List<MedicationLog> logs,
    List<dynamic> members,
  ) {
    final csvData = CsvExporter.generateDoseHistoryCsv(logs, members.cast());
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Export Dose History CSV'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'This report is generated locally on your device without cloud upload.',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondaryLight,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(10),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SelectableText(
                  csvData,
                  style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: csvData));
              Navigator.pop(dialogCtx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('CSV copied to clipboard'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            icon: const Icon(Icons.copy_rounded, size: 18),
            label: const Text('Copy CSV'),
          ),
        ],
      ),
    );
  }
}
